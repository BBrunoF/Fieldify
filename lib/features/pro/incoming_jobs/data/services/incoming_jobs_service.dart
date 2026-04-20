import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/incoming_job.dart';

class JobAlreadyTakenException implements Exception {
  const JobAlreadyTakenException();
  @override
  String toString() => 'Job already taken by another professional.';
}

class ProfessionalProfileMissingException implements Exception {
  const ProfessionalProfileMissingException();
  @override
  String toString() => 'Professional profile not set up.';
}

class IncomingJobsService {
  Future<List<IncomingJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    final proProfile = await supabase
        .from('professional_profiles')
        .select('trade_id')
        .eq('profile_id', user.id)
        .maybeSingle();

    if (proProfile == null || proProfile['trade_id'] == null) {
      throw const ProfessionalProfileMissingException();
    }
    
    final tradeId = proProfile['trade_id'] as int;
    
    final rejectedRows = await supabase
        .from('service_request_rejections')
        .select('request_id')
        .eq('pro_id', user.id);

    final rejectedIds = (rejectedRows as List)
        .map((row) => row['request_id'] as String)
        .toSet();

    var query = supabase
        .from('service_requests')
        .select()
        .eq('status', 'pending')
        .eq('trade_id', tradeId);

    if (!includeRejected && rejectedIds.isNotEmpty) {
      query = query.not('id', 'in', '(${rejectedIds.join(',')})');
    }

    final result = await query.order('created_at', ascending: false);

    return (result as List)
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

    final updated = await supabase
        .from('service_requests')
        .update({
          'pro_id': user.id,
          'status': 'accepted',
          'accepted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('status', 'pending')
        .select();

    if ((updated as List).isEmpty) {
      throw const JobAlreadyTakenException();
    }

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
