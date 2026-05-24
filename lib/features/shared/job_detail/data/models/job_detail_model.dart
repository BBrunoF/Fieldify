enum ViewerRole { client, pro }

enum JobStatus {
  pending,
  accepted,
  onMyWay,
  inProgress,
  completed,
  cancelled;

  static JobStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return JobStatus.pending;
      case 'accepted':
        return JobStatus.accepted;
      case 'on_my_way':
        return JobStatus.onMyWay;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      default:
        return JobStatus.pending;
    }
  }

  String get dbValue {
    switch (this) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.accepted:
        return 'accepted';
      case JobStatus.onMyWay:
        return 'on_my_way';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
    }
  }

  bool get isTerminal =>
      this == JobStatus.completed || this == JobStatus.cancelled;
}

class TradeInfo {
  final int id;
  final String displayName;
  final double standardRate;

  const TradeInfo({
    required this.id,
    required this.displayName,
    required this.standardRate,
  });

  factory TradeInfo.fromJson(Map<String, dynamic> json) {
    return TradeInfo(
      id: json['id'] as int,
      displayName: (json['display_name'] ?? '') as String,
      standardRate: (json['standard_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Timeline {
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? acceptedAt;
  final DateTime? onMyWayAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const Timeline({
    required this.createdAt,
    required this.scheduledAt,
    required this.acceptedAt,
    required this.onMyWayAt,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.cancelReason,
  });

  factory Timeline.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String key) {
      final raw = json[key];
      return raw == null ? null : DateTime.tryParse(raw as String);
    }

    return Timeline(
      createdAt: parse('created_at') ?? DateTime.now(),
      scheduledAt: parse('scheduled_at'),
      acceptedAt: parse('accepted_at'),
      onMyWayAt: parse('on_my_way_at'),
      startedAt: parse('started_at'),
      completedAt: parse('completed_at'),
      cancelledAt: parse('cancelled_at'),
      cancelReason: json['cancel_reason'] as String?,
    );
  }
}

class CounterpartyInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? tradeName;
  final bool isVerifiedPro;

  const CounterpartyInfo({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.phone,
    required this.tradeName,
    required this.isVerifiedPro,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory CounterpartyInfo.fromProfile({
    required Map<String, dynamic> profile,
    required ViewerRole viewerRole,
    String? tradeName,
  }) {
    final isPro = viewerRole == ViewerRole.client;
    final proProfile = profile['professional_profiles'];
    final Map<String, dynamic>? proRow = proProfile is List
        ? (proProfile.isNotEmpty
            ? proProfile.first as Map<String, dynamic>
            : null)
        : proProfile as Map<String, dynamic>?;

    return CounterpartyInfo(
      id: profile['id'] as String,
      fullName: (profile['full_name'] ?? '') as String,
      avatarUrl: profile['avatar_url'] as String?,
      phone: isPro ? null : profile['phone'] as String?,
      tradeName: isPro ? tradeName : null,
      isVerifiedPro:
          isPro && (proRow?['verification_status'] == 'verified'),
    );
  }
}

class ReviewSummary {
  final String id;
  final String requestId;
  final String clientId;
  final String proId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewSummary({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.proId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse((json['created_at'] ?? '') as String) ??
        DateTime.now();
    return ReviewSummary(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      clientId: json['client_id'] as String,
      proId: json['pro_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: created,
    );
  }
}

class JobDetail {
  final String id;
  final String title;
  final String description;
  final String addressText;
  final JobStatus status;
  final String clientId;
  final String? proId;
  final TradeInfo trade;
  final Timeline timeline;
  final List<String> photoUrls;
  final CounterpartyInfo? counterparty;
  final ViewerRole viewerRole;
  final ReviewSummary? review;

  const JobDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.addressText,
    required this.status,
    required this.clientId,
    required this.proId,
    required this.trade,
    required this.timeline,
    required this.photoUrls,
    required this.counterparty,
    required this.viewerRole,
    required this.review,
  });

  factory JobDetail.fromJson({
    required Map<String, dynamic> jobRow,
    required Map<String, dynamic>? counterpartyRow,
    required ViewerRole viewerRole,
    required List<String> photoUrls,
    Map<String, dynamic>? reviewRow,
  }) {
    final tradeJson = jobRow['trades'] as Map<String, dynamic>? ?? const {};
    final trade = TradeInfo.fromJson({
      'id': tradeJson['id'] ?? jobRow['trade_id'],
      'display_name': tradeJson['display_name'] ?? '',
      'standard_rate': tradeJson['standard_rate'] ?? 0,
    });

    return JobDetail(
      id: jobRow['id'] as String,
      title: (jobRow['title'] ?? '') as String,
      description: (jobRow['description'] ?? '') as String,
      addressText: (jobRow['address_text'] ?? '') as String,
      status: JobStatus.fromDb((jobRow['status'] ?? 'pending') as String),
      clientId: jobRow['client_id'] as String,
      proId: jobRow['pro_id'] as String?,
      trade: trade,
      timeline: Timeline.fromJson(jobRow),
      photoUrls: photoUrls,
      counterparty: counterpartyRow == null
          ? null
          : CounterpartyInfo.fromProfile(
              profile: counterpartyRow,
              viewerRole: viewerRole,
              tradeName: trade.displayName,
            ),
      viewerRole: viewerRole,
      review: reviewRow == null ? null : ReviewSummary.fromJson(reviewRow),
    );
  }
}
