import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../accepted_jobs/controllers/accepted_jobs_controller.dart';
import '../../../jobs/presentation/widgets/pro_jobs_view.dart';
import '../../controllers/incoming_jobs_controller.dart';

class IncomingJobsScreen extends StatelessWidget {
  final IncomingJobsController? controller;
  final AcceptedJobsController? acceptedJobsController;

  const IncomingJobsScreen({
    super.key,
    this.controller,
    this.acceptedJobsController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('incomingJobsScreen'),
      backgroundColor: FieldifyColors.surface,
      appBar: AppBar(
        backgroundColor: FieldifyColors.g800,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Jobs',
          key: const Key('incomingJobsAppBarTitle'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      body: ProJobsView(
        incomingJobsController: controller,
        acceptedJobsController: acceptedJobsController,
      ),
    );
  }
}
