import 'package:flutter/foundation.dart';
import '../data/models/pro_job.dart';
import '../data/repositories/pro_jobs_repository.dart';

class ProJobsController extends ChangeNotifier {
  final ProJobsRepository _repository;

  ProJobsController({ProJobsRepository? repository})
      : _repository = repository ?? ProJobsRepository();

  // ── Incoming jobs state ───────────────────────────────────────────────────
  bool _isLoadingIncoming = false;
  List<ProJob> _incomingJobs = const [];
  bool _showRejected = false;

  bool get isLoadingIncoming => _isLoadingIncoming;
  List<ProJob> get incomingJobs => _incomingJobs;
  bool get showRejected => _showRejected;

  // ── Accepted jobs state ───────────────────────────────────────────────────
  bool _isLoadingAccepted = false;
  List<ProJob> _acceptedJobs = const [];

  bool get isLoadingAccepted => _isLoadingAccepted;
  List<ProJob> get acceptedJobs => _acceptedJobs;

  // ── Shared state ──────────────────────────────────────────────────────────
  String? _error;
  String? get error => _error;

  // ── Incoming operations ───────────────────────────────────────────────────

  Future<void> loadIncomingJobs() async {
    _isLoadingIncoming = true;
    _error = null;
    notifyListeners();

    try {
      _incomingJobs = await _repository.fetchIncomingJobs(
        includeRejected: _showRejected,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingIncoming = false;
      notifyListeners();
    }
  }

  Future<void> setShowRejected(bool value) async {
    if (_showRejected == value) return;
    _showRejected = value;
    await loadIncomingJobs();
  }

  Future<void> acceptJob(String requestId) async {
    try {
      await _repository.acceptJob(requestId);
      _incomingJobs =
          _incomingJobs.where((job) => job.id != requestId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectJob(String requestId) async {
    try {
      await _repository.rejectJob(requestId);
      _incomingJobs =
          _incomingJobs.where((job) => job.id != requestId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Accepted operations ───────────────────────────────────────────────────

  Future<void> loadAcceptedJobs() async {
    _isLoadingAccepted = true;
    _error = null;
    notifyListeners();

    try {
      _acceptedJobs = await _repository.fetchAcceptedJobs();
    } catch (e) {
      _error = e.toString();
      _acceptedJobs = const [];
    } finally {
      _isLoadingAccepted = false;
      notifyListeners();
    }
  }

  Future<bool> returnJobToPending(String requestId) async {
    try {
      await _repository.returnJobToPending(requestId);
      _acceptedJobs =
          _acceptedJobs.where((job) => job.id != requestId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
