import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/job_detail_controller.dart';
import '../../data/models/job_detail_model.dart';
import '../widgets/action_bar/job_detail_action_bar.dart';
import '../widgets/cancellation_card.dart';
import '../widgets/counterparty_card.dart';
import '../widgets/job_detail_top_bar.dart';
import '../widgets/job_details_card.dart';
import '../widgets/live_timer_card.dart';
import '../widgets/map_mini_card.dart';
import '../widgets/notice_banner.dart';
import '../widgets/payment_summary_card.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/review_card.dart';
import '../widgets/status_timeline.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  final ViewerRole viewerRole;
  final JobDetailController? controller;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.viewerRole,
    this.controller,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final JobDetailController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        JobDetailController(
          jobId: widget.jobId,
          viewerRole: widget.viewerRole,
        );
    _controller.addListener(_onChange);
    _controller.load();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _controller.detail;
    final title = detail?.title.isNotEmpty == true
        ? detail!.title
        : (detail?.trade.displayName ?? 'Job');

    return Scaffold(
      key: const Key('jobDetailScreen'),
      backgroundColor: FieldifyColors.g800,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            JobDetailTopBar(
              title: title,
              status: detail?.status ?? JobStatus.pending,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: FieldifyColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: _body(detail),
              ),
            ),
            if (detail != null) JobDetailActionBar(controller: _controller),
          ],
        ),
      ),
    );
  }

  Widget _body(JobDetail? detail) {
    if (_controller.isLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _controller.error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3),
          ),
        ),
      );
    }
    if (detail == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: _buildSections(detail),
      ),
    );
  }

  List<Widget> _buildSections(JobDetail detail) {
    final children = <Widget>[];

    void add(Widget w) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(w);
    }

    // Status-specific leading content
    switch (detail.status) {
      case JobStatus.pending:
        add(const NoticeBanner(
          kind: NoticeKind.info,
          text: 'Your request is live. Nearby professionals are being notified — the first to accept gets the job.',
        ));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        add(const NoticeBanner(
          kind: NoticeKind.warn,
          text: 'If no professional accepts within 30 minutes your request expires. No charge will be made.',
        ));
        break;

      case JobStatus.accepted:
        if (detail.counterparty != null) add(CounterpartyCard(info: detail.counterparty!));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        add(StatusTimeline(detail: detail));
        break;

      case JobStatus.onTheWay:
        if (detail.counterparty != null) add(CounterpartyCard(info: detail.counterparty!));
        add(const MapMiniCard(etaLabel: 'ETA coming soon'));
        add(const NoticeBanner(
          kind: NoticeKind.warn,
          text: 'Your card has been authorised. Cancelling now will incur a cancellation fee.',
        ));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        add(StatusTimeline(detail: detail));
        break;

      case JobStatus.inProgress:
        if (detail.timeline.startedAt != null) {
          add(LiveTimerCard(
            startedAt: detail.timeline.startedAt!,
            ratePerHour: detail.trade.standardRate,
          ));
        }
        if (detail.counterparty != null) add(CounterpartyCard(info: detail.counterparty!));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        add(StatusTimeline(detail: detail));
        add(const NoticeBanner(
          kind: NoticeKind.info,
          text: 'Timer runs until the professional marks the job complete. Final cost is calculated on completion.',
        ));
        break;

      case JobStatus.completed:
        if (detail.counterparty != null) add(CounterpartyCard(info: detail.counterparty!));
        add(PaymentSummaryCard(detail: detail));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        if (detail.viewerRole == ViewerRole.client && detail.counterparty != null) {
          add(ReviewCard(counterpartyName: detail.counterparty!.fullName));
        }
        add(StatusTimeline(detail: detail));
        break;

      case JobStatus.cancelled:
        add(const NoticeBanner(
          kind: NoticeKind.danger,
          text: 'This job was cancelled.',
        ));
        add(CancellationCard(detail: detail));
        add(JobDetailsCard(detail: detail));
        if (detail.photoUrls.isNotEmpty) add(PhotoGallery(urls: detail.photoUrls));
        add(StatusTimeline(detail: detail));
        break;
    }

    if (_controller.error != null) {
      add(NoticeBanner(kind: NoticeKind.danger, text: _controller.error!));
    }

    return children;
  }
}
