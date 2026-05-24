import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pro_job.dart';
import '../services/pro_jobs_service.dart';

class ProJobsFailure implements Exception {
  final String message;
  const ProJobsFailure(this.message);

  @override
  String toString() => message;
}

class ProJobsRepository {
  final ProJobsService _service;

  ProJobsRepository({ProJobsService? service})
      : _service = service ?? ProJobsService();

  Future<List<ProJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    try {
      return await _service.fetchIncomingJobs(includeRejected: includeRejected);
    } on ProfessionalProfileMissingException catch (e) {
      throw ProJobsFailure(e.toString());
    } on PostgrestException catch (e) {
      throw ProJobsFailure(e.message);
    }
  }

  Future<List<ProJob>> fetchAcceptedJobs() async {
    try {
      return await _service.fetchAcceptedJobs();
    } on PostgrestException catch (e) {
      throw ProJobsFailure(e.message);
    }
  }

  Future<void> acceptJob(String requestId) async {
    try {
      await _service.acceptJob(requestId);
    } on JobAlreadyTakenException catch (e) {
      throw ProJobsFailure(e.toString());
    } on PostgrestException catch (e) {
      throw ProJobsFailure(e.message);
    }
  }

  Future<void> rejectJob(String requestId) async {
    try {
      await _service.rejectJob(requestId);
    } on PostgrestException catch (e) {
      throw ProJobsFailure(e.message);
    }
  }

  Future<void> returnJobToPending(String requestId) async {
    try {
      await _service.returnJobToPending(requestId);
    } on ProJobReleaseException catch (e) {
      throw ProJobsFailure(e.toString());
    } on PostgrestException catch (e) {
      throw ProJobsFailure(e.message);
    }
  }
}
