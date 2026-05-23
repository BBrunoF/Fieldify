import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/shared/chat/data/models/message_model.dart';

void main() {
  group('Message', () {
    test('fromJson parses a plain text message with defaults', () {
      final msg = Message.fromJson({
        'id': 'm1',
        'request_id': 'r1',
        'sender_id': 'u1',
        'content': 'Hello there',
        'type': 'text',
        'created_at': '2026-05-10T09:00:00Z',
      });

      expect(msg.id, 'm1');
      expect(msg.requestId, 'r1');
      expect(msg.senderId, 'u1');
      expect(msg.content, 'Hello there');
      expect(msg.type, MessageType.text);
      expect(msg.rescheduleProposedAt, isNull);
      expect(msg.rescheduleStatus, isNull);
      expect(msg.readAt, isNull);
      expect(msg.isReschedule, isFalse);
      expect(msg.isReschedulePending, isFalse);
    });

    test('fromJson parses a pending reschedule message', () {
      final msg = Message.fromJson({
        'id': 'm2',
        'request_id': 'r1',
        'sender_id': 'u1',
        'content': '',
        'type': 'reschedule',
        'reschedule_proposed_at': '2026-06-01T14:00:00Z',
        'reschedule_status': 'pending',
        'created_at': '2026-05-10T09:00:00Z',
      });

      expect(msg.type, MessageType.reschedule);
      expect(msg.rescheduleStatus, RescheduleStatus.pending);
      expect(msg.rescheduleProposedAt, isNotNull);
      expect(msg.isReschedule, isTrue);
      expect(msg.isReschedulePending, isTrue);
    });

    test('fromJson maps reschedule status strings to enum values', () {
      RescheduleStatus? parse(String? value) {
        final msg = Message.fromJson({
          'id': 'm',
          'request_id': 'r',
          'sender_id': 'u',
          'content': '',
          'type': value == null ? 'text' : 'reschedule',
          'reschedule_proposed_at':
              value == null ? null : '2026-06-01T14:00:00Z',
          'reschedule_status': value,
          'created_at': '2026-05-10T09:00:00Z',
        });
        return msg.rescheduleStatus;
      }

      expect(parse('pending'), RescheduleStatus.pending);
      expect(parse('accepted'), RescheduleStatus.accepted);
      expect(parse('rejected'), RescheduleStatus.rejected);
      expect(parse(null), isNull);
    });

    test('fromJson defaults missing type to text', () {
      final msg = Message.fromJson({
        'id': 'm',
        'request_id': 'r',
        'sender_id': 'u',
        'content': 'hi',
        'created_at': '2026-05-10T09:00:00Z',
      });

      expect(msg.type, MessageType.text);
    });

    test('isReschedulePending is false once accepted', () {
      final msg = Message.fromJson({
        'id': 'm',
        'request_id': 'r',
        'sender_id': 'u',
        'content': '',
        'type': 'reschedule',
        'reschedule_proposed_at': '2026-06-01T14:00:00Z',
        'reschedule_status': 'accepted',
        'created_at': '2026-05-10T09:00:00Z',
      });

      expect(msg.isReschedule, isTrue);
      expect(msg.isReschedulePending, isFalse);
    });
  });
}
