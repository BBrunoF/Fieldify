// SPLIT FROM: request_screen.dart
import 'package:flutter/foundation.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../data/repositories/request_repository.dart';

class RequestController extends ChangeNotifier {
  final RequestRepository _repo;
  final String? Function() _currentUserIdProvider;

  RequestController({
    RequestRepository? repo,
    String? Function()? currentUserIdProvider,
  }) : _repo = repo ?? RequestRepository(),
       _currentUserIdProvider =
           currentUserIdProvider ?? (() => supabase.auth.currentUser?.id);

  bool _loading = false;
  String? _error;
  bool _submitted = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isSubmitted => _submitted;

  Future<void> submit({
    required int tradeId,
    required String title,
    required String description,
    required String addressText,
    required DateTime? scheduledAt,
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

    try {
      await _repo.submitRequest({
        'client_id': userId,
        'trade_id': tradeId,
        'title': title,
        'description': description,
        'address_text': addressText,
        'location': 'POINT($lng $lat)',
        'scheduled_at': scheduledAt?.toIso8601String(),
        'photo_urls': [],
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
