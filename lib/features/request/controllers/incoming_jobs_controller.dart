import 'package:flutter/foundation.dart';
import '../data/models/incoming_job.dart';
import '../data/repositories/incoming_jobs_repository.dart';

class IncomingJobsController extends ChangeNotifier {
  final IncomingJobsRepository _repository;

  IncomingJobsController({IncomingJobsRepository? repository})
      : _repository = repository ?? IncomingJobsRepository();

  bool _isLoading = false;
  String? _error;
  List<IncomingJob> _jobs = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<IncomingJob> get jobs => _jobs;

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _repository.fetchIncomingJobs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptJob(String requestId) async {
    try {
      await _repository.acceptJob(requestId);
      _jobs = _jobs.where((job) => job.id != requestId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void rejectJobLocally(String requestId) {
    _jobs = _jobs.where((job) => job.id != requestId).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
