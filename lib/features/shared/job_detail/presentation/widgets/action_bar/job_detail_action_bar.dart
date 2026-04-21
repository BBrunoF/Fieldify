import 'package:flutter/material.dart';
import '../../../controllers/job_detail_controller.dart';
import '../../../data/models/job_detail_model.dart';
import 'client_action_bar.dart';
import 'pro_action_bar.dart';

class JobDetailActionBar extends StatelessWidget {
  final JobDetailController controller;
  const JobDetailActionBar({super.key, required this.controller});

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
        onSubmitReview: () {},
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
