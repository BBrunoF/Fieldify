import 'package:flutter/foundation.dart';
import '../data/models/accepted_job.dart';
import '../data/repositories/accepted_jobs_repository.dart';

class AcceptedJobsController extends ChangeNotifier {
  final AcceptedJobsRepository _repository;

  AcceptedJobsController({AcceptedJobsRepository? repository})
    : _repository = repository ?? AcceptedJobsRepository();

  bool _isLoading = false;
  String? _error;
  List<AcceptedJob> _jobs = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AcceptedJob> get jobs => _jobs;

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _repository.fetchAcceptedJobs();
    } catch (e) {
      _error = e.toString();
      _jobs = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> returnJobToPending(String requestId) async {
    try {
      await _repository.returnJobToPending(requestId);
      _jobs = _jobs.where((job) => job.id != requestId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
