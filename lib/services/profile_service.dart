import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _client = Supabase.instance.client;

  Map<String, dynamic> get _meta =>
      Map<String, dynamic>.from(_client.auth.currentUser?.userMetadata ?? {});

  String get fullName => _meta['full_name'] as String? ?? '';
  String get phone => _meta['phone'] as String? ?? '';
  String get email => _client.auth.currentUser?.email ?? '';

  List<String> get addresses {
    final raw = _meta['addresses'];
    if (raw is List) return List<String>.from(raw);
    return [];
  }

  Future<void> updatePersonalDetails({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          ..._meta,
          'full_name': '${firstName.trim()} ${lastName.trim()}',
          'phone': phone.trim(),
        },
      ),
    );
  }

  Future<void> updateAddresses(List<String> addresses) async {
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          ..._meta,
          'addresses': addresses,
        },
      ),
    );
  }
}
