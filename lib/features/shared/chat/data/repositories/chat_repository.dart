import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatFailure implements Exception {
  final String message;
  const ChatFailure(this.message);

  @override
  String toString() => message;
}

class ChatRepository {
  final ChatService _service;

  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  Future<List<Conversation>> fetchConversations() =>
      _guard(() => _service.fetchConversations());

  Future<List<Message>> fetchHistory(String requestId) =>
      _guard(() => _service.fetchHistory(requestId));

  Stream<List<Message>> streamMessages(String requestId) =>
      _service.streamMessages(requestId);

  Stream<void> streamInboxSignal() => _service.streamInboxSignal();

  Future<void> sendMessage(String requestId, String content) =>
      _guard(() => _service.sendMessage(requestId, content));

  Future<void> proposeReschedule(String requestId, DateTime proposedAt,
          {String note = ''}) =>
      _guard(() => _service.proposeReschedule(requestId, proposedAt,
          note: note));

  Future<void> respondReschedule(String messageId, bool accept) =>
      _guard(() => _service.respondReschedule(messageId, accept));

  Future<void> markRead(String requestId) =>
      _guard(() => _service.markRead(requestId));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw ChatFailure(e.message);
    } on AuthException catch (e) {
      throw ChatFailure(e.message);
    }
  }
}
