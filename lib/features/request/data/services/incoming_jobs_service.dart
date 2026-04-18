import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../models/incoming_job.dart';

class IncomingJobsService {
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    final rejectedRows = await supabase
        .from('service_request_rejections')
        .select('request_id')
        .eq('pro_id', user.id);

    final rejectedIds = (rejectedRows as List)
        .map((row) => row['request_id'] as String)
        .toSet();

    final result = await supabase
        .from('service_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (result as List)
        .where((json) => includeRejected || !rejectedIds.contains(json['id']))
        .map(
          (json) => IncomingJob.fromJson(
            json as Map<String, dynamic>,
            isRejected: rejectedIds.contains(json['id']),
          ),
        )
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

    await supabase
        .from('service_request_rejections')
        .delete()
        .eq('pro_id', user.id)
        .eq('request_id', requestId);
  }

  Future<void> rejectJob(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    await supabase.from('service_request_rejections').upsert({
      'pro_id': user.id,
      'request_id': requestId,
    });
  }
}
