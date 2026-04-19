// SPLIT FROM: request_screen.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';

class RequestFailure implements Exception {
  final String message;
  const RequestFailure(this.message);

  @override
  String toString() => message;
}

class RequestRepository {
  Future<void> submitRequest(Map<String, dynamic> data) async {
    try {
      await supabase.from('service_requests').insert(data);
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    }
  }
}
