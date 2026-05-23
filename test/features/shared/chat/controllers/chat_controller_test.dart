import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/chat/controllers/chat_controller.dart';
import 'package:project/features/shared/chat/data/models/message_model.dart';
import 'package:project/features/shared/chat/data/repositories/chat_repository.dart';

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository({
    this.onFetchHistory,
    this.onSendMessage,
  });

  final Future<List<Message>> Function(String requestId)? onFetchHistory;
  final Future<void> Function(String requestId, String content)? onSendMessage;

  int sendMessageCalls = 0;
  int proposeCalls = 0;
  int respondCalls = 0;
  int markReadCalls = 0;
  String? capturedRequestId;
  String? capturedContent;
  DateTime? capturedProposedAt;
  String? capturedMessageId;
  bool? capturedAccept;

  @override
  Future<List<Message>> fetchHistory(String requestId) async {
    return await onFetchHistory?.call(requestId) ?? const [];
  }

  @override
  Stream<List<Message>> streamMessages(String requestId) =>
      const Stream<List<Message>>.empty();

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

  @override
  Future<void> markRead(String requestId) async {
    markReadCalls++;
  }
}

Message _message({
  String id = 'm1',
  String content = 'hello',
  MessageType type = MessageType.text,
  RescheduleStatus? status,
}) {
  return Message.fromJson({
    'id': id,
    'request_id': 'r1',
    'sender_id': 'u1',
    'content': content,
    'type': type == MessageType.reschedule ? 'reschedule' : 'text',
    'reschedule_proposed_at':
        type == MessageType.reschedule ? '2026-06-01T14:00:00Z' : null,
    'reschedule_status': status?.name,
    'created_at': '2026-05-10T09:00:00Z',
  });
}

ChatController _controller({
  String status = 'accepted',
  _FakeChatRepository? repo,
}) {
  return ChatController(
    requestId: 'r1',
    jobStatus: status,
    repository: repo ?? _FakeChatRepository(),
  );
}

void main() {
  group('openChat', () {
    test('is true once the job has an assigned professional', () {
      expect(_controller(status: 'accepted').openChat(), isTrue);
      expect(_controller(status: 'on_my_way').openChat(), isTrue);
      expect(_controller(status: 'in_progress').openChat(), isTrue);
    });

    test('stays true after completion so history remains visible', () {
      expect(_controller(status: 'completed').openChat(), isTrue);
      expect(_controller(status: 'cancelled').openChat(), isTrue);
    });

    test('is false while the job is still pending (no pro yet)', () {
      expect(_controller(status: 'pending').openChat(), isFalse);
    });
  });

  group('lockChatContext', () {
    test('is false during active job states', () {
      expect(_controller(status: 'accepted').lockChatContext(), isFalse);
      expect(_controller(status: 'on_my_way').lockChatContext(), isFalse);
      expect(_controller(status: 'in_progress').lockChatContext(), isFalse);
    });

    test('is true when the job is no longer active', () {
      expect(_controller(status: 'pending').lockChatContext(), isTrue);
      expect(_controller(status: 'completed').lockChatContext(), isTrue);
      expect(_controller(status: 'cancelled').lockChatContext(), isTrue);
    });
  });

  group('validateDateTime', () {
    test('returns an error when the date is null', () {
      expect(ChatController.validateDateTime(null), isNotNull);
    });

    test('returns an error when the date is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(ChatController.validateDateTime(past), isNotNull);
    });

    test('returns null for a valid future date', () {
      final future = DateTime.now().add(const Duration(days: 2));
      expect(ChatController.validateDateTime(future), isNull);
    });
  });

  group('loadChatHistory', () {
    test('populates messages and clears loading flag', () async {
      final controller = _controller(
        repo: _FakeChatRepository(
          onFetchHistory: (_) async => [_message(id: 'a'), _message(id: 'b')],
        ),
      );

      await controller.loadChatHistory();

      expect(controller.messages.map((m) => m.id), ['a', 'b']);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('captures repository errors without throwing', () async {
      final controller = _controller(
        repo: _FakeChatRepository(
          onFetchHistory: (_) async {
            throw const ChatFailure('rls blocked');
          },
        ),
      );

      await controller.loadChatHistory();

      expect(controller.error, 'rls blocked');
      expect(controller.messages, isEmpty);
    });
  });

  group('sendMessage (storeMessage)', () {
    test('trims content and delivers it via the repository', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);

      await controller.sendMessage('  hi there  ');

      expect(repo.sendMessageCalls, 1);
      expect(repo.capturedRequestId, 'r1');
      expect(repo.capturedContent, 'hi there');
    });

    test('is a no-op when content is empty or whitespace', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);

      await controller.sendMessage('');
      await controller.sendMessage('   ');

      expect(repo.sendMessageCalls, 0);
    });

    test('is blocked when the chat context is locked', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(status: 'completed', repo: repo);

      await controller.sendMessage('hi');

      expect(repo.sendMessageCalls, 0);
      expect(controller.error, isNotNull);
    });

    test('exposes ChatFailure message when the send fails', () async {
      final repo = _FakeChatRepository(
        onSendMessage: (_, _) async {
          throw const ChatFailure('network down');
        },
      );
      final controller = _controller(repo: repo);

      await controller.sendMessage('hi');

      expect(controller.error, 'network down');
      expect(controller.isSending, isFalse);
    });
  });

  group('proposeReschedule', () {
    test('forwards a valid future datetime to the repository', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);
      final when = DateTime.now().add(const Duration(days: 2));

      await controller.proposeReschedule(when);

      expect(repo.proposeCalls, 1);
      expect(repo.capturedProposedAt, when);
    });

    test('rejects invalid datetimes without calling the repository', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);
      final past = DateTime.now().subtract(const Duration(days: 1));

      await controller.proposeReschedule(past);

      expect(repo.proposeCalls, 0);
      expect(controller.error, isNotNull);
    });

    test('is blocked when the chat context is locked', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(status: 'completed', repo: repo);
      final when = DateTime.now().add(const Duration(days: 2));

      await controller.proposeReschedule(when);

      expect(repo.proposeCalls, 0);
      expect(controller.error, isNotNull);
    });
  });

  group('confirmReschedule / rejectReschedule', () {
    test('confirmReschedule calls the repo with accept=true', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);
      final pending = _message(
        id: 'pending-1',
        type: MessageType.reschedule,
        status: RescheduleStatus.pending,
      );

      await controller.confirmReschedule(pending);

      expect(repo.respondCalls, 1);
      expect(repo.capturedMessageId, 'pending-1');
      expect(repo.capturedAccept, isTrue);
    });

    test('rejectReschedule calls the repo with accept=false', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);
      final pending = _message(
        id: 'pending-2',
        type: MessageType.reschedule,
        status: RescheduleStatus.pending,
      );

      await controller.rejectReschedule(pending);

      expect(repo.respondCalls, 1);
      expect(repo.capturedMessageId, 'pending-2');
      expect(repo.capturedAccept, isFalse);
    });

    test('ignores responses for messages that are not pending', () async {
      final repo = _FakeChatRepository();
      final controller = _controller(repo: repo);
      final accepted = _message(
        id: 'm',
        type: MessageType.reschedule,
        status: RescheduleStatus.accepted,
      );
      final plainText = _message();

      await controller.confirmReschedule(accepted);
      await controller.rejectReschedule(plainText);

      expect(repo.respondCalls, 0);
    });
  });
}
