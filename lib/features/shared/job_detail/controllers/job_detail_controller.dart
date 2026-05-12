import 'package:flutter/foundation.dart';
import '../data/models/job_detail_model.dart';
import '../data/repositories/job_detail_repository.dart';

class JobDetailController extends ChangeNotifier {
  final String jobId;
  final ViewerRole viewerRole;
  final JobDetailRepository _repo;

  JobDetailController({
    required this.jobId,
    required this.viewerRole,
    JobDetailRepository? repo,
  }) : _repo = repo ?? JobDetailRepository();

  JobDetail? _detail;
  bool _loading = false;
  bool _performingAction = false;
  String? _error;

  JobDetail? get detail => _detail;
  bool get isLoading => _loading;
  bool get isPerformingAction => _performingAction;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _detail = await _repo.fetchJobDetail(jobId, viewerRole);
    } on JobDetailFailure catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load job.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> markOnTheWay() =>
      _runProAction(() => _repo.markOnTheWay(jobId));

  Future<void> markInProgress() =>
      _runProAction(() => _repo.markInProgress(jobId));

  Future<void> markCompleted() =>
      _runProAction(() => _repo.markCompleted(jobId));

  Future<void> cancel({String? reason}) async {
    if (viewerRole != ViewerRole.client) return;
    await _runAction(() => _repo.cancelJob(jobId, reason: reason));
  }

  Future<void> submitReview({required int rating, String? comment}) async {
    if (viewerRole != ViewerRole.client) return;
    final current = _detail;
    if (current == null) return;
    if (current.status != JobStatus.completed) return;
    if (current.review != null) return;
    final proId = current.proId;
    if (proId == null) return;
    if (rating < 1 || rating > 5) {
      _error = 'Please pick a rating between 1 and 5.';
      notifyListeners();
      return;
    }
    await _runAction(() => _repo.submitReview(
          jobId: jobId,
          clientId: current.clientId,
          proId: proId,
          rating: rating,
          comment: comment,
        ));
  }

  Future<void> _runProAction(Future<void> Function() action) async {
    if (viewerRole != ViewerRole.pro) return;
    await _runAction(action);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_performingAction) return;
    _performingAction = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      _detail = await _repo.fetchJobDetail(jobId, viewerRole);
    } on JobDetailFailure catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Action failed.';
    } finally {
      _performingAction = false;
      notifyListeners();
    }
  }
}
