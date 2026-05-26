import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/home/controllers/pro_dashboard_controller.dart';
import 'package:project/features/pro/home/data/models/pro_dashboard_stats.dart';
import 'package:project/features/pro/home/data/repositories/pro_dashboard_repository.dart';

class _FakeProDashboardRepository extends ProDashboardRepository {
  _FakeProDashboardRepository({this.stats, this.error});

  final ProDashboardStats? stats;
  final Object? error;

  @override
  Future<ProDashboardStats> fetchStats() async {
    if (error != null) throw error!;
    return stats ?? ProDashboardStats.empty;
  }
}

const _stats = ProDashboardStats(
  earningsThisMonth: 840,
  earningsLastMonth: 750,
  jobsCompletedAllTime: 42,
  jobsCompletedThisMonth: 3,
  ratingAverage: 4.9,
  ratingCount: 38,
  acceptanceRate: 0.98,
);

void main() {
  test('loads stats from the repository on construction', () async {
    final controller =
        ProDashboardController(repository: _FakeProDashboardRepository(stats: _stats));

    // Let the load() future scheduled in the constructor complete.
    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading, isFalse);
    expect(controller.stats.earningsThisMonth, 840);
    expect(controller.stats.jobsCompletedAllTime, 42);
    expect(controller.stats.ratingAverage, 4.9);
    expect(controller.stats.acceptanceRate, 0.98);
  });

  test('falls back to empty stats when the repository throws', () async {
    final controller = ProDashboardController(
      repository: _FakeProDashboardRepository(error: Exception('boom')),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading, isFalse);
    expect(controller.stats, same(ProDashboardStats.empty));
  });

  test('earningsChangePercent computes month-over-month change', () {
    expect(_stats.earningsChangePercent, 12); // (840-750)/750 = 12%
  });

  test('earningsChangePercent is null when last month had no earnings', () {
    const stats = ProDashboardStats(
      earningsThisMonth: 500,
      earningsLastMonth: 0,
      jobsCompletedAllTime: 1,
      jobsCompletedThisMonth: 1,
      ratingAverage: 0,
      ratingCount: 0,
      acceptanceRate: null,
    );
    expect(stats.earningsChangePercent, isNull);
  });
}
