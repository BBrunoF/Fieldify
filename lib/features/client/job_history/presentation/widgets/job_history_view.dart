import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/job_history_controller.dart';
import 'client_job_card.dart';

class JobHistoryView extends StatefulWidget {
  final JobHistoryController? controller;

  const JobHistoryView({super.key, this.controller});

  @override
  State<JobHistoryView> createState() => _JobHistoryViewState();
}

class _JobHistoryViewState extends State<JobHistoryView> {
  late final JobHistoryController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? JobHistoryController();
    _ownsController = widget.controller == null;
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
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() => _controller.loadJobs();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('jobHistoryView'),
      children: [
        _TabBar(
          selected: _controller.selectedTab,
          activeCount: _controller.activeJobs.length,
          pastCount: _controller.pastJobs.length,
          onChanged: _controller.selectTab,
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: FieldifyColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return ListView(
        key: const Key('jobHistoryLoadingState'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final jobs = _controller.currentJobs;
    if (jobs.isEmpty) {
      return ListView(
        key: const Key('jobHistoryEmptyState'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: Colors.black.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            _controller.selectedTab == JobHistoryTab.active
                ? 'No active jobs right now.'
                : 'No past jobs yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.selectedTab == JobHistoryTab.active
                ? 'Requests you book will appear here.'
                : 'Completed or cancelled jobs show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: FieldifyColors.ink4,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('jobHistoryList'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: jobs.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ClientJobCard(job: jobs[index]);
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  final JobHistoryTab selected;
  final int activeCount;
  final int pastCount;
  final ValueChanged<JobHistoryTab> onChanged;

  const _TabBar({
    required this.selected,
    required this.activeCount,
    required this.pastCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          _TabItem(
            label: 'Active',
            badge: activeCount,
            active: selected == JobHistoryTab.active,
            onTap: () => onChanged(JobHistoryTab.active),
            tabKey: const Key('jobHistoryTabActive'),
          ),
          const SizedBox(width: 32),
          _TabItem(
            label: 'Past',
            badge: pastCount,
            active: selected == JobHistoryTab.past,
            onTap: () => onChanged(JobHistoryTab.past),
            tabKey: const Key('jobHistoryTabPast'),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;
  final Key tabKey;

  const _TabItem({
    required this.label,
    required this.badge,
    required this.active,
    required this.onTap,
    required this.tabKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tabKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : FieldifyColors.g200,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : FieldifyColors.g700,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? FieldifyColors.g800
                          : FieldifyColors.g100,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 2.5,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
