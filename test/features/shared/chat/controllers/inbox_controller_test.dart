import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/chat/controllers/inbox_controller.dart';
import 'package:project/features/shared/chat/data/models/conversation_model.dart';
import 'package:project/features/shared/chat/data/repositories/chat_repository.dart';

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository({this.onFetchConversations});

  final Future<List<Conversation>> Function()? onFetchConversations;

  @override
  Future<List<Conversation>> fetchConversations() async {
    return await onFetchConversations?.call() ?? const [];
  }

  @override
  Stream<void> streamInboxSignal() => const Stream.empty();
}

Conversation _conversation({
  required String requestId,
  required String status,
  DateTime? lastMessageAt,
}) {
  return Conversation(
    requestId: requestId,
    jobTitle: 'Job $requestId',
    jobStatus: status,
    counterpartyId: 'p$requestId',
    counterpartyName: 'Pro $requestId',
    counterpartyAvatarUrl: null,
    lastMessagePreview: null,
    lastMessageAt: lastMessageAt,
    lastMessageFromMe: false,
    unreadCount: 0,
  );
}

void main() {
  group('InboxController', () {
    test('load populates conversations and clears loading flag', () async {
      final controller = InboxController(
        repository: _FakeChatRepository(
          onFetchConversations: () async => [
            _conversation(requestId: '1', status: 'accepted'),
          ],
        ),
      );

      await controller.load();

      expect(controller.conversations, hasLength(1));
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('splits conversations into active and archived buckets', () async {
      final controller = InboxController(
        repository: _FakeChatRepository(
          onFetchConversations: () async => [
            _conversation(requestId: '1', status: 'accepted'),
            _conversation(requestId: '2', status: 'completed'),
            _conversation(requestId: '3', status: 'in_progress'),
            _conversation(requestId: '4', status: 'cancelled'),
          ],
        ),
      );

      await controller.load();

      expect(
        controller.activeConversations.map((c) => c.requestId),
        ['1', '3'],
      );
      expect(
        controller.archivedConversations.map((c) => c.requestId),
        ['2', '4'],
      );
    });

    test('stores error message and empties the list on failure', () async {
      final controller = InboxController(
        repository: _FakeChatRepository(
          onFetchConversations: () async {
            throw const ChatFailure('Could not load conversations');
          },
        ),
      );

      await controller.load();

      expect(controller.error, 'Could not load conversations');
      expect(controller.conversations, isEmpty);
    });
  });
}
