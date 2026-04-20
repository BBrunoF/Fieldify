import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../models/job_history_model.dart';

class JobHistoryService {
  Future<List<ClientJob>> fetchAllJobs() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user.');
    }

    final result = await supabase
        .from('service_requests')
        .select()
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    final jobs = (result as List)
        .map((json) => ClientJob.fromJson(json as Map<String, dynamic>))
        .toList();

    final tradeNames = await _fetchTradeNames(
      jobs.map((j) => j.tradeId).whereType<int>().toSet(),
    );

    return jobs
        .map((j) => j.copyWith(tradeName: tradeNames[j.tradeId]))
        .toList();
  }

  Future<Map<int, String>> _fetchTradeNames(Set<int> tradeIds) async {
    if (tradeIds.isEmpty) return const {};

    final rows = await supabase
        .from('trades')
        .select('id, display_name')
        .inFilter('id', tradeIds.toList());

    return {
      for (final row in rows as List)
        row['id'] as int: (row['display_name'] ?? '') as String,
    };
  }
}
