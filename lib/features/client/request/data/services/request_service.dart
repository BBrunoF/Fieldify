import 'dart:io';
import '../../../../../core/supabase/supabase_client.dart';

const _photosBucket = 'service-request-photos';

class RequestService {
  String? getCurrentUserId() => supabase.auth.currentUser?.id;

  Future<void> submitRequest(Map<String, dynamic> data) async {
    await supabase.from('service_requests').insert(data);
  }

  Future<List<Map<String, dynamic>>> getTrades() async {
    final data = await supabase.from('trades').select().order('id', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }
  Future<String> uploadPhoto({
    required String clientId,
    required String requestId,
    required int index,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$clientId/$requestId/$index.$ext';
    await supabase.storage.from(_photosBucket).upload(path, file);
    return path;
  }
}
