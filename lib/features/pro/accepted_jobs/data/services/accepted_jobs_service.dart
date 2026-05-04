import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/accepted_job.dart';

class AcceptedJobReleaseException implements Exception {
  const AcceptedJobReleaseException();

  @override
  String toString() => 'Could not return this job to incoming requests.';
}

class AcceptedJobsService {
  static const acceptedStatuses = [
    'accepted',
    'on_my_way',
    'on_the_way',
    'in_progress',
  ];

  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    final result = await supabase
        .from('service_requests')
        .select()
        .eq('pro_id', user.id)
        .inFilter('status', acceptedStatuses)
        .order('accepted_at', ascending: true);

    return (result as List)
        .map((json) => AcceptedJob.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> returnJobToPending(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    final updated = await supabase
        .from('service_requests')
        .update({
          'status': 'pending',
          'accepted_at': null,
          'on_my_way_at': null,
          'started_at': null,
          'completed_at': null,
          'cancelled_at': null,
          'cancel_reason': null,
        })
        .eq('id', requestId)
        .eq('pro_id', user.id)
        .inFilter('status', acceptedStatuses)
        .select();

    if ((updated as List).isEmpty) {
      throw const AcceptedJobReleaseException();
    }

    await _clearAssignedProfessionalIfAllowed(requestId, user.id);
  }

  Future<void> _clearAssignedProfessionalIfAllowed(
    String requestId,
    String userId,
  ) async {
    try {
      await supabase
          .from('service_requests')
          .update({'pro_id': null})
          .eq('id', requestId)
          .eq('pro_id', userId)
          .eq('status', 'pending');
    } on PostgrestException {
      // Some RLS policies only let a pro update rows while pro_id stays theirs.
      // The pending status is what makes the request visible/claimable again.
    }
  }
}
