class ProProfileModel {
  final String fullName;
  final String nif;
  final String bio;
  final String verificationStatus;
  final String? avatarPath;
  final String tradeName;
  final int standardRate;

  const ProProfileModel({
    required this.fullName,
    required this.nif,
    required this.bio,
    required this.verificationStatus,
    required this.avatarPath,
    required this.tradeName,
    required this.standardRate,
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
  }) {
    return ProProfileModel(
      fullName: fullName ?? this.fullName,
      nif: nif ?? this.nif,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      avatarPath: avatarPath ?? this.avatarPath,
      tradeName: tradeName ?? this.tradeName,
      standardRate: standardRate ?? this.standardRate,
    );
  }
}
