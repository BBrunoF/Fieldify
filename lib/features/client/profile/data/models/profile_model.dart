class ProfileModel {
  final String fullName;
  final String phone;
  final String email;
  final List<String> addresses;

  const ProfileModel({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.addresses,
  });

  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  factory ProfileModel.fromMeta(Map<String, dynamic> meta, String email) {
    return ProfileModel(
      fullName: meta['full_name'] as String? ?? '',
      phone: meta['phone'] as String? ?? '',
      email: email,
      addresses: meta['addresses'] is List
          ? List<String>.from(meta['addresses'] as List)
          : [],
    );
  }

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    List<String>? addresses,
  }) {
    return ProfileModel(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addresses: addresses ?? this.addresses,
    );
  }
}
