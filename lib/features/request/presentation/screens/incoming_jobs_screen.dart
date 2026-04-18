import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/incoming_jobs_view.dart';

class IncomingJobsScreen extends StatelessWidget {
  const IncomingJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldifyColors.surface,
      appBar: AppBar(
        backgroundColor: FieldifyColors.g800,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Incoming jobs',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      body: const IncomingJobsView(),
    );
  }
}
