class AcceptedJob {
  final String id;
  final String title;
  final String description;
  final String? addressText;
  final String status;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final String clientId;

  const AcceptedJob({
    required this.id,
    required this.title,
    required this.description,
    required this.addressText,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
    required this.clientId,
  });

  factory AcceptedJob.fromJson(Map<String, dynamic> json) {
    return AcceptedJob(
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
      clientId: (json['client_id'] ?? '') as String,
    );
  }
}
