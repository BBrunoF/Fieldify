import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/accepted_job.dart';

class AcceptedJobsService {
  static const acceptedStatuses = ['accepted', 'on_my_way', 'in_progress'];

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
}
