import 'package:flutter/material.dart';
import '../../../controllers/job_detail_controller.dart';
import '../../../data/models/job_detail_model.dart';
import '../review_card.dart';
import 'client_action_bar.dart';
import 'pro_action_bar.dart';

class JobDetailActionBar extends StatelessWidget {
  final JobDetailController controller;
  const JobDetailActionBar({super.key, required this.controller});

  Future<void> _openReviewSheet(BuildContext context) async {
    final detail = controller.detail;
    if (detail == null) return;
    if (detail.review != null) return;
    final counterparty = detail.counterparty;
    assert(
      counterparty != null,
      'Cannot open review sheet without counterparty for job ${detail.id}',
    );
    if (counterparty == null) return;

    await ReviewSubmissionSheet.show(
      context,
      counterpartyName: counterparty.fullName,
      isBusy: () => controller.isPerformingAction,
      onSubmit: (rating, comment) async {
        final ok = await controller.submitReview(
          rating: rating,
          comment: comment,
        );
        if (ok) return null;
        return controller.error ?? "Couldn't submit your review. Please try again.";
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail;
    if (detail == null) return const SizedBox.shrink();

    if (detail.viewerRole == ViewerRole.client) {
      return ClientActionBar(
        detail: detail,
        isBusy: controller.isPerformingAction,
        onCancel: () => controller.cancel(),
        onMessage: () {},
        onSubmitReview: () => _openReviewSheet(context),
        onSubmitNewRequest: () => Navigator.of(context).pop(),
      );
    }

    return ProActionBar(
      detail: detail,
      isBusy: controller.isPerformingAction,
      onMessage: () {},
      onMarkOnTheWay: controller.markOnTheWay,
      onMarkInProgress: controller.markInProgress,
      onMarkCompleted: controller.markCompleted,
    );
  }
}
