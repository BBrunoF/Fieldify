import '../../../../../core/supabase/supabase_client.dart';
import '../models/pro_dashboard_stats.dart';

class ProDashboardService {
  /// Loads the aggregated dashboard metrics for the current professional.
  ///
  /// All metrics are scoped to the authenticated user as `pro_id` (which is the
  /// profile id throughout this schema). Returns [ProDashboardStats.empty] when
  /// there is no authenticated user.
  Future<ProDashboardStats> fetchStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return ProDashboardStats.empty;

    final proId = user.id;
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final results = await Future.wait([
      _fetchEarnings(proId, startOfLastMonth, startOfThisMonth),
      _fetchJobsCompleted(proId, startOfThisMonth),
      _fetchRating(proId),
      _fetchAcceptanceRate(proId, thirtyDaysAgo),
    ]);

    final earnings = results[0] as _Earnings;
    final jobs = results[1] as _JobsCompleted;
    final rating = results[2] as _Rating;
    final acceptanceRate = results[3] as double?;

    return ProDashboardStats(
      earningsThisMonth: earnings.thisMonth,
      earningsLastMonth: earnings.lastMonth,
      jobsCompletedAllTime: jobs.allTime,
      jobsCompletedThisMonth: jobs.thisMonth,
      ratingAverage: rating.average,
      ratingCount: rating.count,
      acceptanceRate: acceptanceRate,
    );
  }

  Future<_Earnings> _fetchEarnings(
    String proId,
    DateTime startOfLastMonth,
    DateTime startOfThisMonth,
  ) async {
    final rows = await supabase
        .from('payments')
        .select('amount_charged, captured_at')
        .eq('pro_id', proId)
        .eq('status', 'captured')
        .gte('captured_at', startOfLastMonth.toUtc().toIso8601String());

    var thisMonth = 0.0;
    var lastMonth = 0.0;
    for (final row in rows as List) {
      final amount = (row['amount_charged'] as num?)?.toDouble() ?? 0;
      final capturedAt =
          DateTime.tryParse((row['captured_at'] ?? '') as String)?.toLocal();
      if (capturedAt == null) continue;
      if (!capturedAt.isBefore(startOfThisMonth)) {
        thisMonth += amount;
      } else {
        lastMonth += amount;
      }
    }
    return _Earnings(thisMonth: thisMonth, lastMonth: lastMonth);
  }

  Future<_JobsCompleted> _fetchJobsCompleted(
    String proId,
    DateTime startOfThisMonth,
  ) async {
    final rows = await supabase
        .from('service_requests')
        .select('completed_at')
        .eq('pro_id', proId)
        .eq('status', 'completed');

    final list = rows as List;
    var thisMonth = 0;
    for (final row in list) {
      final completedAt =
          DateTime.tryParse((row['completed_at'] ?? '') as String)?.toLocal();
      if (completedAt != null && !completedAt.isBefore(startOfThisMonth)) {
        thisMonth++;
      }
    }
    return _JobsCompleted(allTime: list.length, thisMonth: thisMonth);
  }

  Future<_Rating> _fetchRating(String proId) async {
    final rows = await supabase
        .from('reviews')
        .select('rating')
        .eq('pro_id', proId);

    final list = rows as List;
    if (list.isEmpty) return const _Rating(average: 0, count: 0);
    final sum = list.fold<int>(
      0,
      (acc, row) => acc + ((row['rating'] as num?)?.toInt() ?? 0),
    );
    return _Rating(average: sum / list.length, count: list.length);
  }

  Future<double?> _fetchAcceptanceRate(
    String proId,
    DateTime since,
  ) async {
    final sinceIso = since.toUtc().toIso8601String();

    final accepted = await supabase
        .from('service_requests')
        .select('id')
        .eq('pro_id', proId)
        .gte('accepted_at', sinceIso);

    final rejected = await supabase
        .from('service_request_rejections')
        .select('request_id')
        .eq('pro_id', proId)
        .gte('created_at', sinceIso);

    final acceptedCount = (accepted as List).length;
    final rejectedCount = (rejected as List).length;
    final total = acceptedCount + rejectedCount;
    if (total == 0) return null;
    return acceptedCount / total;
  }
}

class _Earnings {
  final double thisMonth;
  final double lastMonth;
  const _Earnings({required this.thisMonth, required this.lastMonth});
}

class _JobsCompleted {
  final int allTime;
  final int thisMonth;
  const _JobsCompleted({required this.allTime, required this.thisMonth});
}

class _Rating {
  final double average;
  final int count;
  const _Rating({required this.average, required this.count});
}
