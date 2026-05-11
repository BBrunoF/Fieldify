import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/pro_jobs_controller.dart';
import 'accepted_job_card.dart';

class AcceptedJobsView extends StatefulWidget {
  final ProJobsController? controller;
  final VoidCallback? onJobReturnedToIncoming;

  const AcceptedJobsView({
    super.key,
    this.controller,
    this.onJobReturnedToIncoming,
  });

  @override
  State<AcceptedJobsView> createState() => _AcceptedJobsViewState();
}

class _AcceptedJobsViewState extends State<AcceptedJobsView> {
  late final ProJobsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProJobsController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.loadAcceptedJobs();
    });
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
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _controller.loadAcceptedJobs();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _controller.isLoadingAccepted
          ? ListView(
              key: const Key('acceptedJobsLoadingState'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _controller.acceptedJobs.isEmpty
          ? ListView(
              key: const Key('acceptedJobsEmptyState'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 56,
                  color: Colors.black.withAlpha(80),
                ),
                const SizedBox(height: 16),
                Text(
                  'No accepted jobs right now.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accepted and active work will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: FieldifyColors.ink4,
                  ),
                ),
              ],
            )
          : ListView.separated(
              key: const Key('acceptedJobsList'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: _controller.acceptedJobs.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = _controller.acceptedJobs[index];
                return AcceptedJobCard(
                  key: ValueKey('acceptedJobCard_${job.id}'),
                  job: job,
                  onCancel: () async {
                    final returned =
                        await _controller.returnJobToPending(job.id);
                    if (returned) {
                      widget.onJobReturnedToIncoming?.call();
                    }
                  },
                );
              },
            ),
    );
  }
}
