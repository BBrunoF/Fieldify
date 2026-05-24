class ProJob {
  final String id;
  final String title;
  final String description;
  final String? addressText;
  final String status;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? acceptedAt;
  final String clientId;
  final bool isRejected;

  const ProJob({
    required this.id,
    required this.title,
    required this.description,
    required this.addressText,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.acceptedAt,
    required this.clientId,
    this.isRejected = false,
  });

  factory ProJob.fromJson(
    Map<String, dynamic> json, {
    bool isRejected = false,
  }) {
    return ProJob(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      addressText: json['address_text'] as String?,
      status: (json['status'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      clientId: (json['client_id'] ?? '') as String,
      isRejected: isRejected,
    );
  }
}
