import '../../../../../core/supabase/supabase_client.dart';
import '../models/job_detail_model.dart';

const _photosBucket = 'service-request-photos';
const _signedUrlTtlSeconds = 60 * 60;

class JobDetailService {
  Future<JobDetail> fetchJobDetail(
    String jobId,
    ViewerRole viewerRole,
  ) async {
    final jobRow = await supabase
        .from('service_requests')
        .select('*, trades(id, display_name, standard_rate)')
        .eq('id', jobId)
        .single();

    final counterpartyId = viewerRole == ViewerRole.client
        ? jobRow['pro_id'] as String?
        : jobRow['client_id'] as String?;

    final counterpartyRow = await _fetchCounterparty(counterpartyId, viewerRole);
    final photoPaths = (jobRow['photo_urls'] as List?)?.cast<String>() ?? const [];
    final photoUrls = await _signedPhotoUrls(photoPaths);
    final reviewRow = await _fetchReviewForRequest(jobId);

    return JobDetail.fromJson(
      jobRow: jobRow,
      counterpartyRow: counterpartyRow,
      viewerRole: viewerRole,
      photoUrls: photoUrls,
      reviewRow: reviewRow,
    );
  }

  Future<Map<String, dynamic>?> _fetchReviewForRequest(String jobId) async {
    return await supabase
        .from('reviews')
        .select('id, request_id, client_id, pro_id, rating, comment, created_at')
        .eq('request_id', jobId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _fetchCounterparty(
    String? id,
    ViewerRole viewerRole,
  ) async {
    if (id == null) return null;

    if (viewerRole == ViewerRole.client) {
      return await supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url, '
            'professional_profiles(verification_status, bio, trade_id)',
          )
          .eq('id', id)
          .maybeSingle();
    }

    return await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, phone')
        .eq('id', id)
        .maybeSingle();
  }

  Future<List<String>> _signedPhotoUrls(List<String> paths) async {
    if (paths.isEmpty) return const [];
    final result = await supabase.storage
        .from(_photosBucket)
        .createSignedUrls(paths, _signedUrlTtlSeconds);
    return result.map((r) => r.signedUrl).toList();
  }

  Future<void> markOnTheWay(String jobId) async {
    await supabase
        .from('service_requests')
        .update({
          'status': JobStatus.onMyWay.dbValue,
          'on_my_way_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', jobId);
  }

  Future<void> markInProgress(String jobId) async {
    await supabase
        .from('service_requests')
        .update({
          'status': JobStatus.inProgress.dbValue,
          'started_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', jobId);
  }

  Future<void> markCompleted(String jobId) async {
    await supabase
        .from('service_requests')
        .update({
          'status': JobStatus.completed.dbValue,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', jobId);
  }

  Future<void> submitReview({
    required String jobId,
    required String clientId,
    required String proId,
    required int rating,
    String? comment,
  }) async {
    final trimmed = comment?.trim();
    await supabase.from('reviews').insert({
      'request_id': jobId,
      'client_id': clientId,
      'pro_id': proId,
      'rating': rating,
      'comment': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    });
  }

  Future<void> cancelJob(String jobId, {String? reason}) async {
    await supabase
        .from('service_requests')
        .update({
          'status': JobStatus.cancelled.dbValue,
          'cancelled_at': DateTime.now().toUtc().toIso8601String(),
          'cancel_reason': ?reason,
        })
        .eq('id', jobId);
  }
}
