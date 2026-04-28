import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accepted_job.dart';
import '../services/accepted_jobs_service.dart';

class AcceptedJobsFailure implements Exception {
  final String message;
  const AcceptedJobsFailure(this.message);

  @override
  String toString() => message;
}

class AcceptedJobsRepository {
  final AcceptedJobsService _service;

  AcceptedJobsRepository({AcceptedJobsService? service})
    : _service = service ?? AcceptedJobsService();

  Future<List<AcceptedJob>> fetchAcceptedJobs() async {
    try {
      return await _service.fetchAcceptedJobs();
    } on PostgrestException catch (e) {
      throw AcceptedJobsFailure(e.message);
    }
  }
}
