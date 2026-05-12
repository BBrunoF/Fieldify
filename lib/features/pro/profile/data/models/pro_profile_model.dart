class ProReview {
  final String id;
  final int rating;
  final String? comment;
  final String clientName;
  final DateTime createdAt;

  const ProReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.clientName,
    required this.createdAt,
  });

  factory ProReview.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final Map<String, dynamic>? profileRow = profile is Map<String, dynamic>
        ? profile
        : (profile is List && profile.isNotEmpty
            ? profile.first as Map<String, dynamic>
            : null);

    return ProReview(
      id: json['id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      clientName: (profileRow?['full_name'] ?? '') as String,
      createdAt: DateTime.tryParse((json['created_at'] ?? '') as String) ??
          DateTime.now(),
    );
  }
}

class ProRatingSummary {
  final double average;
  final int count;

  const ProRatingSummary({required this.average, required this.count});

  static const empty = ProRatingSummary(average: 0, count: 0);

  static ProRatingSummary fromReviews(Iterable<ProReview> reviews) {
    final list = reviews.toList();
    if (list.isEmpty) return empty;
    final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
    return ProRatingSummary(
      average: sum / list.length,
      count: list.length,
    );
  }
}

class ProProfileModel {
  final String fullName;
  final String nif;
  final String bio;
  final String verificationStatus;
  final String? avatarPath;
  final String tradeName;
  final int standardRate;
  final List<String> credentialUrls;
  final int? serviceRadiusKm;

  const ProProfileModel({
    required this.fullName,
    required this.nif,
    required this.bio,
    required this.verificationStatus,
    required this.avatarPath,
    required this.tradeName,
    required this.standardRate,
    required this.credentialUrls,
    this.serviceRadiusKm,
  });

  bool get isApproved => verificationStatus == 'approved';

  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  String get initials {
    final f = firstName;
    final l = lastName;
    if (f.isEmpty) return '?';
    if (l.isEmpty) return f.substring(0, 1).toUpperCase();
    return (f.substring(0, 1) + l.substring(0, 1)).toUpperCase();
  }

  ProProfileModel copyWith({
    String? fullName,
    String? nif,
    String? bio,
    String? verificationStatus,
    String? avatarPath,
    String? tradeName,
    int? standardRate,
    List<String>? credentialUrls,
    int? serviceRadiusKm,
  }) {
    return ProProfileModel(
      fullName: fullName ?? this.fullName,
      nif: nif ?? this.nif,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      avatarPath: avatarPath ?? this.avatarPath,
      tradeName: tradeName ?? this.tradeName,
      standardRate: standardRate ?? this.standardRate,
      credentialUrls: credentialUrls ?? this.credentialUrls,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
    );
  }
}
