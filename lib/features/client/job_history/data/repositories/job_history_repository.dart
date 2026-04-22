import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_history_model.dart';
import '../services/job_history_service.dart';

class JobHistoryFailure implements Exception {
  final String message;
  const JobHistoryFailure(this.message);

  @override
  String toString() => message;
}

class JobHistoryRepository {
  final JobHistoryService _service;

  JobHistoryRepository({JobHistoryService? service})
      : _service = service ?? JobHistoryService();

  Future<List<ClientJob>> fetchAllJobs() async {
    try {
      return await _service.fetchAllJobs();
    } on PostgrestException catch (e) {
      throw JobHistoryFailure(e.message);
    }
  }
}
