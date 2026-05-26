import '../models/pro_dashboard_stats.dart';
import '../services/pro_dashboard_service.dart';

class ProDashboardFailure implements Exception {
  final String message;
  const ProDashboardFailure(this.message);

  @override
  String toString() => message;
}

class ProDashboardRepository {
  final ProDashboardService _service;

  ProDashboardRepository({ProDashboardService? service})
      : _service = service ?? ProDashboardService();

  Future<ProDashboardStats> fetchStats() async {
    try {
      return await _service.fetchStats();
    } catch (e) {
      throw ProDashboardFailure(e.toString());
    }
  }
}
