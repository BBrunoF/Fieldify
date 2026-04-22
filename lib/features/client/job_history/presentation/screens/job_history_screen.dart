import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/job_history_controller.dart';
import '../widgets/job_history_view.dart';

class JobHistoryScreen extends StatelessWidget {
  final JobHistoryController? controller;

  const JobHistoryScreen({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('jobHistoryScreen'),
      backgroundColor: FieldifyColors.g800,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: FieldifyColors.g800,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
              alignment: Alignment.centerLeft,
              child: Text(
                'My jobs',
                key: const Key('jobHistoryHeader'),
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Expanded(child: JobHistoryView(controller: controller)),
          ],
        ),
      ),
    );
  }
}
