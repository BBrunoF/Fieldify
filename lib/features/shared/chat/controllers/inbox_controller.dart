import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/conversation_model.dart';
import '../data/repositories/chat_repository.dart';

class InboxController extends ChangeNotifier {
  final ChatRepository _repository;
  StreamSubscription<void>? _signalSub;

  InboxController({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  bool _isLoading = false;
  String? _error;
  List<Conversation> _conversations = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Conversation> get conversations => _conversations;

  List<Conversation> get activeConversations =>
      _conversations.where((c) => c.isActive).toList();
  List<Conversation> get archivedConversations =>
      _conversations.where((c) => !c.isActive).toList();

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _repository.fetchConversations();
    } catch (e) {
      _error = e.toString();
      _conversations = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload the list whenever any message the user can see changes.
  void listenForUpdates() {
    _signalSub ??= _repository.streamInboxSignal().listen((_) {
      _refreshQuietly();
    });
  }

  Future<void> _refreshQuietly() async {
    try {
      _conversations = await _repository.fetchConversations();
      notifyListeners();
    } catch (_) {
      // Keep the last good list on a transient stream/refresh error.
    }
  }

  @override
  void dispose() {
    _signalSub?.cancel();
    super.dispose();
  }
}
