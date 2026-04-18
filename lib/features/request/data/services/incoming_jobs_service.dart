import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../models/incoming_job.dart';

class IncomingJobsService {
  Future<List<IncomingJob>> fetchIncomingJobs() async {
    final result = await supabase
        .from('service_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (result as List)
        .map((json) => IncomingJob.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptJob(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    await supabase.from('service_requests').update({
      'pro_id': user.id,
      'status': 'accepted',
      'accepted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId);
  }
}
