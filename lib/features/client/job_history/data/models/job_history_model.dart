class ClientJob {
  final String id;
  final String title;
  final String description;
  final String? addressText;
  final String status;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final String? proId;
  final int? tradeId;
  final String? tradeName;

  const ClientJob({
    required this.id,
    required this.title,
    required this.description,
    required this.addressText,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
    required this.proId,
    required this.tradeId,
    required this.tradeName,
  });

  bool get isPast => status == 'completed' || status == 'cancelled';

  String get proInitials {
    final source = (proId ?? '').replaceAll('-', '');
    if (source.length >= 2) return source.substring(0, 2).toUpperCase();
    return 'PR';
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'On the way';
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  String get displaySubtitle {
    if (proId == null) return tradeName ?? 'Awaiting professional';
    if (tradeName == null || tradeName!.isEmpty) return 'Assigned professional';
    return 'Assigned pro · $tradeName';
  }

  ClientJob copyWith({String? tradeName}) {
    return ClientJob(
      id: id,
      title: title,
      description: description,
      addressText: addressText,
      status: status,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      proId: proId,
      tradeId: tradeId,
      tradeName: tradeName ?? this.tradeName,
    );
  }

  factory ClientJob.fromJson(Map<String, dynamic> json) {
    return ClientJob(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      addressText: json['address_text'] as String?,
      status: (json['status'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      proId: json['pro_id'] as String?,
      tradeId: json['trade_id'] as int?,
      tradeName: null,
    );
  }
}
