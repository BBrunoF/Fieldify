const _activeStatuses = {'accepted', 'on_my_way', 'in_progress'};

/// One chat thread, scoped to a single service request (job).
class Conversation {
  final String requestId;
  final String jobTitle;
  final String jobStatus;
  final String counterpartyId;
  final String counterpartyName;
  final String? counterpartyAvatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final bool lastMessageFromMe;
  final int unreadCount;

  const Conversation({
    required this.requestId,
    required this.jobTitle,
    required this.jobStatus,
    required this.counterpartyId,
    required this.counterpartyName,
    required this.counterpartyAvatarUrl,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.lastMessageFromMe,
    required this.unreadCount,
  });

  bool get isActive => _activeStatuses.contains(jobStatus);

  /// Used to order the inbox: most recent activity first.
  DateTime get sortKey =>
      lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  String get counterpartyInitials {
    final parts = counterpartyName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Conversation copyWith({
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    bool? lastMessageFromMe,
    int? unreadCount,
  }) {
    return Conversation(
      requestId: requestId,
      jobTitle: jobTitle,
      jobStatus: jobStatus,
      counterpartyId: counterpartyId,
      counterpartyName: counterpartyName,
      counterpartyAvatarUrl: counterpartyAvatarUrl,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
