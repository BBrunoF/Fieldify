import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/chat/data/models/message_model.dart';
import 'package:project/features/shared/chat/data/repositories/chat_repository.dart';
import 'package:project/features/shared/chat/data/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeChatService extends ChatService {
  _FakeChatService({
    this.onFetchHistory,
    this.onSendMessage,
  });

  final Future<List<Message>> Function(String requestId)? onFetchHistory;
  final Future<void> Function(String requestId, String content)? onSendMessage;

  int sendMessageCalls = 0;
  int proposeCalls = 0;
  int respondCalls = 0;
  String? capturedRequestId;
  String? capturedContent;
  DateTime? capturedProposedAt;
  bool? capturedAccept;
  String? capturedMessageId;

  @override
  Future<List<Message>> fetchHistory(String requestId) async {
    return await onFetchHistory?.call(requestId) ?? const [];
  }

  @override
  Future<void> sendMessage(String requestId, String content) async {
    sendMessageCalls++;
    capturedRequestId = requestId;
    capturedContent = content;
    if (onSendMessage != null) await onSendMessage!(requestId, content);
  }

  @override
  Future<void> proposeReschedule(
    String requestId,
    DateTime proposedAt, {
    String note = '',
  }) async {
    proposeCalls++;
    capturedRequestId = requestId;
    capturedProposedAt = proposedAt;
  }

  @override
  Future<void> respondReschedule(String messageId, bool accept) async {
    respondCalls++;
    capturedMessageId = messageId;
    capturedAccept = accept;
  }
}

Message _msg(String id) => Message.fromJson({
      'id': id,
      'request_id': 'r1',
      'sender_id': 'u1',
      'content': 'hi',
      'type': 'text',
      'created_at': '2026-05-10T09:00:00Z',
    });

void main() {
  group('ChatRepository.fetchHistory', () {
    test('returns history produced by the service', () async {
      final repo = ChatRepository(
        service: _FakeChatService(onFetchHistory: (_) async => [_msg('m1')]),
      );

      final result = await repo.fetchHistory('r1');

      expect(result, hasLength(1));
      expect(result.single.id, 'm1');
    });

    test('wraps PostgrestException into ChatFailure', () async {
      final repo = ChatRepository(
        service: _FakeChatService(
          onFetchHistory: (_) async {
            throw PostgrestException(message: 'db offline');
          },
        ),
      );

      await expectLater(
        () => repo.fetchHistory('r1'),
        throwsA(
          isA<ChatFailure>().having(
            (e) => e.message,
            'message',
            'db offline',
          ),
        ),
      );
    });

    test('wraps AuthException into ChatFailure', () async {
      final repo = ChatRepository(
        service: _FakeChatService(
          onFetchHistory: (_) async {
            throw const AuthException('No authenticated user.');
          },
        ),
      );

      await expectLater(
        () => repo.fetchHistory('r1'),
        throwsA(
          isA<ChatFailure>().having(
            (e) => e.message,
            'message',
            'No authenticated user.',
          ),
        ),
      );
    });
  });

  group('ChatRepository.sendMessage (storeMessage)', () {
    test('delegates to the service with the exact arguments', () async {
      final service = _FakeChatService();
      final repo = ChatRepository(service: service);

      await repo.sendMessage('r1', 'hello');

      expect(service.sendMessageCalls, 1);
      expect(service.capturedRequestId, 'r1');
      expect(service.capturedContent, 'hello');
    });

    test('wraps Postgrest errors into ChatFailure', () async {
      final repo = ChatRepository(
        service: _FakeChatService(
          onSendMessage: (_, _) async {
            throw PostgrestException(message: 'rls blocked');
          },
        ),
      );

      await expectLater(
        () => repo.sendMessage('r1', 'hello'),
        throwsA(
          isA<ChatFailure>().having(
            (e) => e.message,
            'message',
            'rls blocked',
          ),
        ),
      );
    });
  });

  group('ChatRepository reschedule actions', () {
    test('proposeReschedule forwards the proposed datetime', () async {
      final service = _FakeChatService();
      final repo = ChatRepository(service: service);
      final when = DateTime.utc(2026, 6, 1, 14);

      await repo.proposeReschedule('r1', when, note: 'sorry');

      expect(service.proposeCalls, 1);
      expect(service.capturedRequestId, 'r1');
      expect(service.capturedProposedAt, when);
    });

    test('respondReschedule forwards messageId and accept flag', () async {
      final service = _FakeChatService();
      final repo = ChatRepository(service: service);

      await repo.respondReschedule('m1', true);
      expect(service.respondCalls, 1);
      expect(service.capturedMessageId, 'm1');
      expect(service.capturedAccept, isTrue);

      await repo.respondReschedule('m2', false);
      expect(service.respondCalls, 2);
      expect(service.capturedMessageId, 'm2');
      expect(service.capturedAccept, isFalse);
    });
  });
}
