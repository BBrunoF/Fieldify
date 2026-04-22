import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/incoming_jobs_controller.dart';
import '../widgets/incoming_jobs_view.dart';

class IncomingJobsScreen extends StatelessWidget {
  final IncomingJobsController? controller;

  const IncomingJobsScreen({super.key, this.controller});

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
          'Incoming jobs',
          key: const Key('incomingJobsAppBarTitle'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      body: IncomingJobsView(controller: controller),
    );
  }
}
