import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';

const _activeStatuses = {'accepted', 'on_my_way', 'in_progress'};

class ChatController extends ChangeNotifier {
  final ChatRepository _repository;
  final String requestId;

  /// Current job status. Drives whether the chat is locked (read-only).
  String jobStatus;

  StreamSubscription<List<Message>>? _sub;

  ChatController({
    required this.requestId,
    required this.jobStatus,
    ChatRepository? repository,
  }) : _repository = repository ?? ChatRepository();

  bool _isLoading = false;
  String? _error;
  bool _isSending = false;
  List<Message> _messages = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSending => _isSending;
  List<Message> get messages => _messages;

  String? get currentUserId => supabase.auth.currentUser?.id;

  /// True while the job is active. Chat input is only enabled here.
  bool get isJobActive => _activeStatuses.contains(jobStatus);

  /// Chat is locked (archived / read-only) outside an active job.
  bool lockChatContext() => !isJobActive;
  bool get isLocked => lockChatContext();

  /// Whether the chat can be opened at all. History stays viewable even
  /// when archived, so opening is always allowed once a pro is assigned.
  bool openChat() => true;

  Future<void> loadChatHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _repository.fetchHistory(requestId);
      _subscribe();
      await _markReadSafely();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _sub ??= _repository.streamMessages(requestId).listen((messages) {
      _messages = messages;
      notifyListeners();
      _markReadSafely();
    });
  }

  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty || _isSending) return;
    if (isLocked) {
      _error = 'This job is no longer active — the chat is read-only.';
      notifyListeners();
      return;
    }
    _isSending = true;
    notifyListeners();
    try {
      await _repository.sendMessage(requestId, text);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Validates a proposed reschedule date/time.
  /// Returns an error message, or null when valid.
  static String? validateDateTime(DateTime? proposed) {
    if (proposed == null) return 'Pick a date and time.';
    if (!proposed.isAfter(DateTime.now())) {
      return 'Pick a date and time in the future.';
    }
    return null;
  }

  Future<void> proposeReschedule(DateTime proposedAt, {String note = ''}) async {
    if (isLocked) {
      _error = 'This job is no longer active — the chat is read-only.';
      notifyListeners();
      return;
    }
    final validationError = validateDateTime(proposedAt);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }
    try {
      await _repository.proposeReschedule(requestId, proposedAt, note: note);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> respondReschedule(Message message, bool accept) async {
    if (!message.isReschedulePending) return;
    try {
      await _repository.respondReschedule(message.id, accept);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> confirmReschedule(Message message) =>
      respondReschedule(message, true);
  Future<void> rejectReschedule(Message message) =>
      respondReschedule(message, false);

  Future<void> _markReadSafely() async {
    try {
      await _repository.markRead(requestId);
    } catch (_) {
      // Read receipts are best-effort.
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
