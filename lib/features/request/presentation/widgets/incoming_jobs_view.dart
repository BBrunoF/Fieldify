import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/incoming_jobs_controller.dart';
import 'incoming_job_card.dart';

class IncomingJobsView extends StatefulWidget {
  const IncomingJobsView({super.key});

  @override
  State<IncomingJobsView> createState() => _IncomingJobsViewState();
}

class _IncomingJobsViewState extends State<IncomingJobsView> {
  final IncomingJobsController _controller = IncomingJobsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.loadJobs();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    final error = _controller.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      _controller.clearError();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _controller.loadJobs();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _controller.isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _controller.jobs.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Icon(Icons.work_outline,
                        size: 56, color: Colors.black.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text(
                      'No pending jobs right now.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh when new requests arrive.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: FieldifyColors.ink4,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  itemCount: _controller.jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = _controller.jobs[index];
                    return IncomingJobCard(
                      job: job,
                      onAccept: () => _controller.acceptJob(job.id),
                      onReject: () => _controller.rejectJobLocally(job.id),
                    );
                  },
                ),
    );
  }
}
