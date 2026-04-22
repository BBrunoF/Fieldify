import 'package:flutter/foundation.dart';
import '../data/models/job_history_model.dart';
import '../data/repositories/job_history_repository.dart';

enum JobHistoryTab { active, past }

class JobHistoryController extends ChangeNotifier {
  final JobHistoryRepository _repository;

  JobHistoryController({JobHistoryRepository? repository})
      : _repository = repository ?? JobHistoryRepository();

  bool _isLoading = false;
  String? _error;
  List<ClientJob> _activeJobs = const [];
  List<ClientJob> _pastJobs = const [];
  JobHistoryTab _selectedTab = JobHistoryTab.active;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ClientJob> get activeJobs => _activeJobs;
  List<ClientJob> get pastJobs => _pastJobs;
  JobHistoryTab get selectedTab => _selectedTab;

  List<ClientJob> get currentJobs =>
      _selectedTab == JobHistoryTab.active ? _activeJobs : _pastJobs;

  void selectTab(JobHistoryTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _repository.fetchAllJobs();
      _activeJobs = all.where((j) => !j.isPast).toList();
      _pastJobs = all.where((j) => j.isPast).toList();
    } catch (e) {
      _error = e.toString();
      _activeJobs = const [];
      _pastJobs = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
