import 'package:flutter/foundation.dart';
import '../data/models/payment_models.dart';
import '../data/repositories/payment_repository.dart';

class PaymentMethodsController extends ChangeNotifier {
  final PaymentRepository _repo;

  PaymentMethodsController({PaymentRepository? repo})
      : _repo = repo ?? PaymentRepository();

  List<SavedCard> _cards = const [];
  bool _loading = false;
  bool _addingCard = false;
  String? _error;

  List<SavedCard> get cards => _cards;
  bool get isLoading => _loading;
  bool get isAddingCard => _addingCard;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cards = await _repo.fetchCards();
    } on PaymentException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your cards.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Launches Stripe's PaymentSheet to add a card. Returns true if a card was
  /// saved. The webhook persists the row asynchronously, so we briefly poll
  /// until it shows up.
  Future<bool> addCard() async {
    if (_addingCard) return false;
    _addingCard = true;
    _error = null;
    notifyListeners();
    try {
      final added = await _repo.addCard();
      if (added) {
        await _reloadUntilNewCard(_cards.length);
      }
      return added;
    } on PaymentException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _addingCard = false;
      notifyListeners();
    }
  }

  /// Sets [cardId] as the default and refreshes the list.
  Future<void> setDefault(String cardId) async {
    if (_addingCard) return;
    _error = null;
    notifyListeners();
    try {
      await _repo.setDefaultCard(cardId);
      _cards = await _repo.fetchCards();
    } on PaymentException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Webhook writes the card row a beat after the sheet closes — poll a few
  /// times so the new card appears without a manual pull-to-refresh.
  Future<void> _reloadUntilNewCard(int previousCount) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      _cards = await _repo.fetchCards();
      if (_cards.length > previousCount) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }
}
