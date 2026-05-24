import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/supabase/supabase_client.dart';
import '../../../../pro/profile/data/models/availability_schedule_model.dart';
import '../models/pro_job.dart';

class JobAlreadyTakenException implements Exception {
  const JobAlreadyTakenException();
  @override
  String toString() => 'Job already taken by another professional.';
}

class ProfessionalProfileMissingException implements Exception {
  const ProfessionalProfileMissingException();
  @override
  String toString() => 'Professional profile not set up.';
}

class ProJobReleaseException implements Exception {
  const ProJobReleaseException();
  @override
  String toString() => 'Could not return this job to incoming requests.';
}

class ProJobsService {
  static const acceptedStatuses = [
    'accepted',
    'on_my_way',
    'on_the_way',
    'in_progress',
  ];

  Future<List<ProJob>> fetchIncomingJobs({
    bool includeRejected = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('No authenticated user.');

    final proProfile = await supabase
        .from('professional_profiles')
        .select('id, trade_id')
        .eq('profile_id', user.id)
        .maybeSingle();

    if (proProfile == null || proProfile['trade_id'] == null) {
      throw const ProfessionalProfileMissingException();
    }

    final proId = proProfile['id'] as String;
    final tradeId = proProfile['trade_id'] as int;

    final rejectedRows = await supabase
        .from('service_request_rejections')
        .select('request_id')
        .eq('pro_id', user.id);

    final rejectedIds = (rejectedRows as List)
        .map((row) => row['request_id'] as String)
        .toSet();

    var query = supabase
        .from('service_requests')
        .select()
        .eq('status', 'pending')
        .eq('trade_id', tradeId);

    if (!includeRejected && rejectedIds.isNotEmpty) {
      query = query.not('id', 'in', '(${rejectedIds.join(',')})');
    }

    final result = await query.order('created_at', ascending: false);

    var jobs = (result as List)
        .map(
          (json) => ProJob.fromJson(
            json as Map<String, dynamic>,
            isRejected: rejectedIds.contains(json['id']),
          ),
        )
        .toList();

    // Filter by pro's availability schedule.
    // Jobs with no scheduled_at (ASAP) are always shown.
    // Jobs with a scheduled_at are only shown if they fall within a slot.
    try {
      final scheduleRows = await supabase
          .from('availability_schedules')
          .select()
          .eq('pro_id', proId);

      final slots = (scheduleRows as List)
          .cast<Map<String, dynamic>>()
          .map(AvailabilityScheduleModel.fromJson)
          .toList();

      if (slots.isNotEmpty) {
        jobs = jobs.where((job) {
          final scheduledAt = job.scheduledAt;
          if (scheduledAt == null) return true;

          final local = scheduledAt.toLocal();
          final dayOfWeek = local.weekday - 1; // weekday 1=Mon → 0=Mon
          final jobMinutes = local.hour * 60 + local.minute;

          return slots.any((s) =>
              s.dayOfWeek == dayOfWeek &&
              jobMinutes >= s.startMinutes &&
              jobMinutes < s.endMinutes);
        }).toList();
      }
    } catch (e) {
      // Availability filtering is best-effort; on failure show all jobs rather
      // than hiding work, but surface the cause for debugging.
      debugPrint('IncomingJobsService: availability filter failed: $e');
    }

    return jobs;
  }

  Future<List<ProJob>> fetchAcceptedJobs() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('No authenticated user.');

    final result = await supabase
        .from('service_requests')
        .select()
        .eq('pro_id', user.id)
        .inFilter('status', acceptedStatuses)
        .order('accepted_at', ascending: true);

    return (result as List)
        .map((json) => ProJob.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptJob(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('No authenticated user.');

    final updated = await supabase
        .from('service_requests')
        .update({
          'pro_id': user.id,
          'status': 'accepted',
          'accepted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('status', 'pending')
        .select();

    if ((updated as List).isEmpty) throw const JobAlreadyTakenException();

    await supabase
        .from('service_request_rejections')
        .delete()
        .eq('pro_id', user.id)
        .eq('request_id', requestId);
  }

  Future<void> rejectJob(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('No authenticated user.');

    await supabase.from('service_request_rejections').upsert({
      'pro_id': user.id,
      'request_id': requestId,
    });
  }

  Future<void> returnJobToPending(String requestId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw const AuthException('No authenticated user.');

    final updated = await supabase
        .from('service_requests')
        .update({
          'status': 'pending',
          'accepted_at': null,
          'on_my_way_at': null,
          'started_at': null,
          'completed_at': null,
          'cancelled_at': null,
          'cancel_reason': null,
        })
        .eq('id', requestId)
        .eq('pro_id', user.id)
        .inFilter('status', acceptedStatuses)
        .select();

    if ((updated as List).isEmpty) throw const ProJobReleaseException();

    // Best-effort: clear pro_id now that status is pending.
    // Requires the RLS UPDATE policy to permit pro_id=null on owned rows.
    try {
      await supabase
          .from('service_requests')
          .update({'pro_id': null})
          .eq('id', requestId)
          .eq('pro_id', user.id)
          .eq('status', 'pending');
    } on PostgrestException {
      // RLS blocks pro_id clear — fix the UPDATE policy to allow
      // setting pro_id=null when OLD.pro_id = auth.uid().
    }
  }
}
