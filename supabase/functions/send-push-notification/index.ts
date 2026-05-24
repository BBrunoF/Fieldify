import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

const STATUS_MESSAGES: Record<string, string> = {
  accepted: 'Your job request has been accepted!',
  on_my_way: 'The professional is on their way.',
  in_progress: 'Your job has started.',
  completed: 'Your job has been completed.',
  cancelled: 'Your job has been cancelled.',
};

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

  const header = encode({ alg: 'RS256', typ: 'JWT' });
  const payload = encode({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  });

  const signingInput = `${header}.${payload}`;

  const pemBody = sa.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '');

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const jwt = `${signingInput}.${signatureB64}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  return data.access_token as string;
}

serve(async (req) => {
  try {
    const { record, old_record } = await req.json();

    // Only act when status actually changes
    if (!record || record.status === old_record?.status) {
      return new Response('No status change', { status: 200 });
    }

    const body = STATUS_MESSAGES[record.status as string];
    if (!body) return new Response('Status not notifiable', { status: 200 });

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const clientId = record.client_id as string;
    if (!clientId) return new Response('No client_id in record', { status: 200 });

    const { data: tokens } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', clientId);

    if (!tokens || tokens.length === 0) {
      return new Response('No FCM token for client', { status: 200 });
    }

    const sa: ServiceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);
    const accessToken = await getGoogleAccessToken(sa);

    await Promise.all(
      tokens.map(({ token }: { token: string }) =>
        fetch(
          `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title: 'Fieldify', body },
                data: { job_id: record.id, status: record.status },
              },
            }),
          },
        )
      ),
    );

    return new Response('OK', { status: 200 });
  } catch (e) {
    return new Response(String(e), { status: 500 });
  }
});
