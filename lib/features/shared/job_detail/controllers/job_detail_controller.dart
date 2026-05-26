import 'package:flutter/foundation.dart';
import '../../payments/data/models/payment_models.dart';
import '../../payments/data/repositories/payment_repository.dart';
import '../data/models/job_detail_model.dart';
import '../data/repositories/job_detail_repository.dart';

/// Upper bound on a single job, mirrors MAX_JOB_HOURS in the edge functions —
/// the authorisation covers `rate × this`.
const _maxJobHours = 8;

/// Minimum billable duration: every job is charged for at least 30 minutes,
/// however short the actual time worked.
const _minBillableHours = 0.5;

class JobDetailController extends ChangeNotifier {
  final String jobId;
  final ViewerRole viewerRole;
  final JobDetailRepository _repo;
  final PaymentRepository _payments;

  JobDetailController({
    required this.jobId,
    required this.viewerRole,
    JobDetailRepository? repo,
    PaymentRepository? paymentRepository,
  })  : _repo = repo ?? JobDetailRepository(),
        _payments = paymentRepository ?? PaymentRepository.resolve();

  JobDetail? _detail;
  PaymentInfo? _payment;
  bool _loading = false;
  bool _performingAction = false;
  String? _error;

  JobDetail? get detail => _detail;
  PaymentInfo? get payment => _payment;
  bool get isLoading => _loading;
  bool get isPerformingAction => _performingAction;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _detail = await _repo.fetchJobDetail(jobId, viewerRole);
      _payment = await _payments.fetchPaymentForRequest(jobId);
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

  /// Pro completes the job. If the client authorised a payment, capture the
  /// actual amount (the capture function also flips the request to completed).
  /// Otherwise fall back to a plain status update so the flow never dead-ends.
  Future<void> markCompleted() => _runProAction(() async {
        // Always attempt capture — the capture function looks the payment up by
        // request_id with admin rights, so this works even when RLS hides the
        // (still pro_id-null) payment row from the pro. Fall back to a plain
        // completion only when there is genuinely no authorised payment.
        try {
          await _payments.capture(
            requestId: jobId,
            amountEuros: _computeCaptureAmount(),
          );
        } on PaymentException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('no payment') || msg.contains('cannot capture')) {
            await _repo.markCompleted(jobId);
          } else {
            rethrow;
          }
        }
      });

  /// Charge the worked hours at the trade rate, clamped to the authorised
  /// ceiling (rate × max hours) which is what Stripe is holding.
  double _computeCaptureAmount() {
    final d = _detail;
    if (d == null) return 0.01;
    final rate = d.trade.standardRate;
    final start = d.timeline.startedAt;
    final hours = start == null
        ? _minBillableHours
        : DateTime.now().toUtc().difference(start).inSeconds / 3600.0;
    final clampedHours = hours.clamp(_minBillableHours, _maxJobHours.toDouble());
    final amount = double.parse((rate * clampedHours).toStringAsFixed(2));
    final ceiling = _payment?.amountAuthorised ?? (rate * _maxJobHours);
    return amount > ceiling ? ceiling : amount;
  }

  Future<void> cancel({String? reason}) async {
    if (viewerRole != ViewerRole.client) return;
    await _runAction(() => _repo.cancelJob(jobId, reason: reason));
  }

  Future<bool> submitReview({required int rating, String? comment}) async {
    if (viewerRole != ViewerRole.client) return false;
    final current = _detail;
    if (current == null) return false;
    if (current.status != JobStatus.completed) return false;
    if (current.review != null) return false;
    final proId = current.proId;
    if (proId == null) return false;
    if (rating < 1 || rating > 5) {
      _error = 'Please pick a rating between 1 and 5.';
      notifyListeners();
      return false;
    }
    if (_performingAction) return false;
    _performingAction = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.submitReview(
        jobId: jobId,
        clientId: current.clientId,
        proId: proId,
        rating: rating,
        comment: comment,
      );
      _detail = await _repo.fetchJobDetail(jobId, viewerRole);
      return true;
    } on JobDetailFailure catch (_) {
      _error = "Couldn't submit your review. Please try again.";
      return false;
    } catch (_) {
      _error = "Couldn't submit your review. Please try again.";
      return false;
    } finally {
      _performingAction = false;
      notifyListeners();
    }
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
      _payment = await _payments.fetchPaymentForRequest(jobId);
    } on JobDetailFailure catch (e) {
      _error = e.message;
    } on PaymentException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Action failed.';
    } finally {
      _performingAction = false;
      notifyListeners();
    }
  }
}
