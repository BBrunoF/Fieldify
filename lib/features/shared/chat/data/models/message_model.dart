enum MessageType { text, reschedule }

enum RescheduleStatus { pending, accepted, rejected }

class Message {
  final String id;
  final String requestId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime? rescheduleProposedAt;
  final RescheduleStatus? rescheduleStatus;
  final DateTime? rescheduleRespondedAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.rescheduleProposedAt,
    required this.rescheduleStatus,
    required this.rescheduleRespondedAt,
    required this.readAt,
    required this.createdAt,
  });

  bool get isReschedule => type == MessageType.reschedule;
  bool get isReschedulePending =>
      isReschedule && rescheduleStatus == RescheduleStatus.pending;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      senderId: json['sender_id'] as String,
      content: (json['content'] ?? '') as String,
      type: _typeFromString(json['type'] as String?),
      rescheduleProposedAt: _parseDate(json['reschedule_proposed_at']),
      rescheduleStatus: _statusFromString(
        json['reschedule_status'] as String?,
      ),
      rescheduleRespondedAt: _parseDate(json['reschedule_responded_at']),
      readAt: _parseDate(json['read_at']),
      createdAt:
          _parseDate(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String)?.toLocal();
  }

  static MessageType _typeFromString(String? value) {
    return value == 'reschedule' ? MessageType.reschedule : MessageType.text;
  }

  static RescheduleStatus? _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return RescheduleStatus.pending;
      case 'accepted':
        return RescheduleStatus.accepted;
      case 'rejected':
        return RescheduleStatus.rejected;
      default:
        return null;
    }
  }
}
