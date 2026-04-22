// SPLIT FROM: request_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../data/models/trade_model.dart';
import '../data/repositories/request_repository.dart';

class RequestController extends ChangeNotifier {
  final RequestRepository _repo;
  final String? Function() _currentUserIdProvider;
  final String Function() _requestIdGenerator;

  RequestController({
    RequestRepository? repo,
    String? Function()? currentUserIdProvider,
    String Function()? requestIdGenerator,
  }) : _repo = repo ?? RequestRepository(),
       _currentUserIdProvider =
           currentUserIdProvider ?? (() => supabase.auth.currentUser?.id),
       _requestIdGenerator =
           requestIdGenerator ?? (() => const Uuid().v4());

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
    required DateTime? scheduledAt,
    List<File> photos = const [],
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final userId = _currentUserIdProvider();
    if (userId == null) {
      _loading = false;
      _error = 'No authenticated user.';
      notifyListeners();
      return;
    }

    // Hardcoded Porto coords until Google Maps geocoding is wired up
    const lat = 41.1579;
    const lng = -8.6291;

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
        'location': 'POINT($lng $lat)',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'photo_urls': photoPaths,
      });
      _submitted = true;
    } on RequestFailure catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}