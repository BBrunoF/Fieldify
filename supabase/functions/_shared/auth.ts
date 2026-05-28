import { userClient } from "./supabase.ts";

export type AuthSuccess = { ok: true; user: { id: string; email?: string }; jwt: string };
export type AuthFailure = { ok: false; status: number; message: string };
export type AuthResult = AuthSuccess | AuthFailure;

export async function authenticate(req: Request): Promise<AuthResult> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return { ok: false, status: 401, message: "Missing Authorization header" };
  }

  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  const supabase = userClient(jwt);
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return { ok: false, status: 401, message: "Invalid or expired token" };
  }

  return { ok: true, user: { id: user.id, email: user.email }, jwt };
}
