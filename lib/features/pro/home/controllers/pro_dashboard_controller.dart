import 'package:flutter/foundation.dart';
import '../data/models/pro_dashboard_stats.dart';
import '../data/repositories/pro_dashboard_repository.dart';

class ProDashboardController extends ChangeNotifier {
  final ProDashboardRepository _repository;

  ProDashboardController({ProDashboardRepository? repository})
      : _repository = repository ?? ProDashboardRepository() {
    load();
  }

  ProDashboardStats _stats = ProDashboardStats.empty;
  bool _isLoading = true;

  ProDashboardStats get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stats = await _repository.fetchStats();
    } catch (_) {
      // Best-effort dashboard: fall back to empty rather than blocking the
      // home screen with an error state.
      _stats = ProDashboardStats.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
