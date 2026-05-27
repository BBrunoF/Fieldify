// SPLIT FROM: request_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/payments/data/models/payment_models.dart';
import '../../../shared/payments/data/repositories/payment_repository.dart';
import '../data/models/trade_model.dart';
import '../data/repositories/request_repository.dart';

class RequestController extends ChangeNotifier {
  final RequestRepository _repo;
  final PaymentRepository _payments;
  final String? Function()? _currentUserIdOverride;
  final String Function() _requestIdGenerator;

  RequestController({
    RequestRepository? repo,
    PaymentRepository? paymentRepository,
    String? Function()? currentUserIdProvider,
    String Function()? requestIdGenerator,
  }) : _repo = repo ?? RequestRepository(),
       _payments = paymentRepository ?? PaymentRepository.resolve(),
       _currentUserIdOverride = currentUserIdProvider,
       _requestIdGenerator =
           requestIdGenerator ?? (() => const Uuid().v4());

  String? get _currentUserId =>
      _currentUserIdOverride != null
          ? _currentUserIdOverride()
          : _repo.getCurrentUserId();

  bool _loading = false;
  String? _error;
  bool _submitted = false;

  List<Trade> _trades = const [];
  bool _loadingTrades = false;
  String? _tradesError;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isSubmitted => _submitted;

  List<Trade> get trades => _trades;
  bool get isLoadingTrades => _loadingTrades;
  String? get tradesError => _tradesError;

  Future<void> loadTrades() async {
    _loadingTrades = true;
    _tradesError = null;
    notifyListeners();

    try {
      _trades = await _repo.getTrades();
    } on RequestFailure catch (e) {
      _tradesError = e.message;
    } catch (e) {
      _tradesError = 'Could not load categories.';
    } finally {
      _loadingTrades = false;
      notifyListeners();
    }
  }

  Future<void> submit({
    required int tradeId,
    required String title,
    required String description,
    required String addressText,
    required double latitude,
    required double longitude,
    required DateTime? scheduledAt,
    List<File> photos = const [],
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final userId = _currentUserId;
    if (userId == null) {
      _loading = false;
      _error = 'No authenticated user.';
      notifyListeners();
      return;
    }

    // A card must be on file: the request authorises a hold up front.
    String? cardId;
    try {
      cardId = await _payments.defaultCardId();
    } catch (_) {
      cardId = null;
    }
    if (cardId == null) {
      _loading = false;
      _error = 'Add a payment card before submitting your request.';
      notifyListeners();
      return;
    }

    final requestId = _requestIdGenerator();

    try {
      final photoPaths = photos.isEmpty
          ? <String>[]
          : await _repo.uploadPhotos(
              clientId: userId,
              requestId: requestId,
              files: photos,
            );

      await _repo.submitRequest({
        'id': requestId,
        'client_id': userId,
        'trade_id': tradeId,
        'title': title,
        'description': description,
        'address_text': addressText,
        'location': 'POINT($longitude $latitude)',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'photo_urls': photoPaths,
      });

      // Authorise the hold now that the request row exists.
      await _payments.authorise(requestId: requestId, paymentMethodId: cardId);
      _submitted = true;
    } on RequestFailure catch (e) {
      _error = e.message;
    } on PaymentException catch (e) {
      _error = 'Request created but card authorisation failed: ${e.message}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}