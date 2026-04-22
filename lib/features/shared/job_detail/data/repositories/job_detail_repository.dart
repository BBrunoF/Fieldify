import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_detail_model.dart';
import '../services/job_detail_service.dart';

class JobDetailFailure implements Exception {
  final String message;
  const JobDetailFailure(this.message);

  @override
  String toString() => message;
}

class JobDetailRepository {
  final JobDetailService _service;

  JobDetailRepository({JobDetailService? service})
      : _service = service ?? JobDetailService();

  Future<JobDetail> fetchJobDetail(
    String jobId,
    ViewerRole viewerRole,
  ) async {
    try {
      return await _service.fetchJobDetail(jobId, viewerRole);
    } on PostgrestException catch (e) {
      throw JobDetailFailure(e.message);
    } on StorageException catch (e) {
      throw JobDetailFailure(e.message);
    }
  }

  Future<void> markOnTheWay(String jobId) async {
    try {
      await _service.markOnTheWay(jobId);
    } on PostgrestException catch (e) {
      throw JobDetailFailure(e.message);
    }
  }

  Future<void> markInProgress(String jobId) async {
    try {
      await _service.markInProgress(jobId);
    } on PostgrestException catch (e) {
      throw JobDetailFailure(e.message);
    }
  }

  Future<void> markCompleted(String jobId) async {
    try {
      await _service.markCompleted(jobId);
    } on PostgrestException catch (e) {
      throw JobDetailFailure(e.message);
    }
  }

  Future<void> cancelJob(String jobId, {String? reason}) async {
    try {
      await _service.cancelJob(jobId, reason: reason);
    } on PostgrestException catch (e) {
      throw JobDetailFailure(e.message);
    }
  }
}
