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
  final DateTime? jobAcceptedAt;
  final DateTime? jobCreatedAt;

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
    this.jobAcceptedAt,
    this.jobCreatedAt,
  });

  bool get isActive => _activeStatuses.contains(jobStatus);

  /// Used to order the inbox: most recent activity first. Falls back to the
  /// job's accepted/created timestamps so a brand new active conversation
  /// (no messages yet) still bubbles up near the top.
  DateTime get sortKey {
    final candidates = <DateTime>[
      ?lastMessageAt,
      ?jobAcceptedAt,
      ?jobCreatedAt,
    ];
    if (candidates.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return candidates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

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
      jobAcceptedAt: jobAcceptedAt,
      jobCreatedAt: jobCreatedAt,
    );
  }
}
