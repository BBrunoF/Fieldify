import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/pro/home/controllers/pro_dashboard_controller.dart';
import 'package:project/features/pro/home/data/models/pro_dashboard_stats.dart';
import 'package:project/features/pro/home/data/repositories/pro_dashboard_repository.dart';
import 'package:project/features/pro/home/presentation/widgets/pro_dashboard_view.dart';

class _FakeProDashboardRepository extends ProDashboardRepository {
  _FakeProDashboardRepository(this.stats);
  final ProDashboardStats stats;

  @override
  Future<ProDashboardStats> fetchStats() async => stats;
}

class _GatedProDashboardRepository extends ProDashboardRepository {
  _GatedProDashboardRepository(this.gate);
  final Future<void> gate;

  @override
  Future<ProDashboardStats> fetchStats() async {
    await gate;
    return ProDashboardStats.empty;
  }
}

Future<void> _pump(WidgetTester tester, ProDashboardStats stats) async {
  final controller =
      ProDashboardController(repository: _FakeProDashboardRepository(stats));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ProDashboardView(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all four metric values', (tester) async {
    await _pump(
      tester,
      const ProDashboardStats(
        earningsThisMonth: 840,
        earningsLastMonth: 750,
        jobsCompletedAllTime: 42,
        jobsCompletedThisMonth: 3,
        ratingAverage: 4.9,
        ratingCount: 38,
        acceptanceRate: 0.98,
      ),
    );

    expect(find.text('€840'), findsOneWidget);
    expect(find.text('+12% vs last month'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('3 this month'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('based on 38 reviews'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
  });

  testWidgets('shows empty states for a brand-new pro', (tester) async {
    await _pump(tester, ProDashboardStats.empty);

    expect(find.text('€0'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
    // Rating value and acceptance rate both render an em-dash.
    expect(find.text('—'), findsNWidgets(2));
    // No month-over-month line when last month had no earnings.
    expect(find.textContaining('vs last month'), findsNothing);
  });

  testWidgets('shows a loading spinner before stats resolve', (tester) async {
    final gate = Completer<void>();
    final controller = ProDashboardController(
      repository: _GatedProDashboardRepository(gate.future),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProDashboardView(controller: controller)),
      ),
    );

    // load() is held open by the gate, so we're still loading.
    expect(find.byKey(const Key('dashboardLoading')), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboardGrid')), findsOneWidget);
  });
}
