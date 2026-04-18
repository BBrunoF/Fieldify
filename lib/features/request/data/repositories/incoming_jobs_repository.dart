import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incoming_job.dart';
import '../services/incoming_jobs_service.dart';

class IncomingJobsFailure implements Exception {
  final String message;
  const IncomingJobsFailure(this.message);

  @override
  String toString() => message;
}

class IncomingJobsRepository {
  final IncomingJobsService _service;

  IncomingJobsRepository({IncomingJobsService? service})
      : _service = service ?? IncomingJobsService();

  Future<List<IncomingJob>> fetchIncomingJobs() async {
    try {
      return await _service.fetchIncomingJobs();
    } on PostgrestException catch (e) {
      throw IncomingJobsFailure(e.message);
    }
  }

  Future<void> acceptJob(String requestId) async {
    try {
      await _service.acceptJob(requestId);
    } on PostgrestException catch (e) {
      throw IncomingJobsFailure(e.message);
    }
  }
}
