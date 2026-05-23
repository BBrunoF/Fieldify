import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/chat/data/models/conversation_model.dart';

Conversation _conversation({
  String requestId = 'r1',
  String jobStatus = 'accepted',
  String counterpartyName = 'Manuel Silva',
  DateTime? lastMessageAt,
}) {
  return Conversation(
    requestId: requestId,
    jobTitle: 'Pipe leak',
    jobStatus: jobStatus,
    counterpartyId: 'p1',
    counterpartyName: counterpartyName,
    counterpartyAvatarUrl: null,
    lastMessagePreview: null,
    lastMessageAt: lastMessageAt,
    lastMessageFromMe: false,
    unreadCount: 0,
  );
}

void main() {
  group('Conversation', () {
    test('isActive is true for accepted/on_my_way/in_progress', () {
      expect(_conversation(jobStatus: 'accepted').isActive, isTrue);
      expect(_conversation(jobStatus: 'on_my_way').isActive, isTrue);
      expect(_conversation(jobStatus: 'in_progress').isActive, isTrue);
    });

    test('isActive is false for completed/cancelled/pending', () {
      expect(_conversation(jobStatus: 'completed').isActive, isFalse);
      expect(_conversation(jobStatus: 'cancelled').isActive, isFalse);
      expect(_conversation(jobStatus: 'pending').isActive, isFalse);
    });

    test('sortKey uses lastMessageAt or epoch fallback', () {
      final dated = _conversation(
        lastMessageAt: DateTime.utc(2026, 5, 10, 12),
      );
      final empty = _conversation();

      expect(dated.sortKey, DateTime.utc(2026, 5, 10, 12));
      expect(empty.sortKey, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('counterpartyInitials builds from first + last name parts', () {
      expect(
        _conversation(counterpartyName: 'Manuel Silva').counterpartyInitials,
        'MS',
      );
      expect(
        _conversation(counterpartyName: 'Madonna').counterpartyInitials,
        'M',
      );
      expect(
        _conversation(counterpartyName: '   ').counterpartyInitials,
        '?',
      );
    });

    test('copyWith only updates the supplied fields', () {
      final base = _conversation();
      final updated = base.copyWith(
        lastMessagePreview: 'Hi',
        lastMessageAt: DateTime.utc(2026, 5, 20),
        unreadCount: 3,
      );

      expect(updated.lastMessagePreview, 'Hi');
      expect(updated.lastMessageAt, DateTime.utc(2026, 5, 20));
      expect(updated.unreadCount, 3);
      expect(updated.requestId, base.requestId);
      expect(updated.counterpartyName, base.counterpartyName);
      expect(updated.jobStatus, base.jobStatus);
    });
  });
}
