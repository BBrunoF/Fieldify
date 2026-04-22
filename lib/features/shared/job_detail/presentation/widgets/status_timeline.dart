import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/job_detail_model.dart';

class TimelineEntry {
  final String label;
  final String? sub;
  final TimelineState state;
  const TimelineEntry({required this.label, this.sub, required this.state});
}

enum TimelineState { done, active, pending, cancelled }

class StatusTimeline extends StatelessWidget {
  final JobDetail detail;
  const StatusTimeline({super.key, required this.detail});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  List<TimelineEntry> _buildEntries() {
    final t = detail.timeline;
    final s = detail.status;
    final entries = <TimelineEntry>[];

    entries.add(TimelineEntry(
      label: 'Request submitted',
      sub: _fmt(t.createdAt),
      state: TimelineState.done,
    ));

    if (s == JobStatus.cancelled) {
      if (t.acceptedAt != null) {
        entries.add(TimelineEntry(
          label: 'Professional accepted',
          sub: _fmt(t.acceptedAt),
          state: TimelineState.done,
        ));
      }
      if (t.onMyWayAt != null) {
        entries.add(TimelineEntry(
          label: 'On the way',
          sub: _fmt(t.onMyWayAt),
          state: TimelineState.done,
        ));
      }
      entries.add(TimelineEntry(
        label: 'Cancelled',
        sub: t.cancelReason ?? _fmt(t.cancelledAt),
        state: TimelineState.cancelled,
      ));
      return entries;
    }

    entries.add(TimelineEntry(
      label: 'Professional accepted',
      sub: t.acceptedAt != null ? _fmt(t.acceptedAt) : null,
      state: t.acceptedAt != null
          ? TimelineState.done
          : (s == JobStatus.pending ? TimelineState.active : TimelineState.pending),
    ));

    entries.add(TimelineEntry(
      label: 'On the way',
      sub: t.onMyWayAt != null ? _fmt(t.onMyWayAt) : null,
      state: t.onMyWayAt != null
          ? TimelineState.done
          : (s == JobStatus.accepted ? TimelineState.active : TimelineState.pending),
    ));

    entries.add(TimelineEntry(
      label: 'In progress',
      sub: t.startedAt != null ? _fmt(t.startedAt) : null,
      state: t.startedAt != null
          ? (s == JobStatus.inProgress ? TimelineState.active : TimelineState.done)
          : (s == JobStatus.onTheWay ? TimelineState.active : TimelineState.pending),
    ));

    entries.add(TimelineEntry(
      label: 'Completed',
      sub: t.completedAt != null ? _fmt(t.completedAt) : null,
      state: s == JobStatus.completed ? TimelineState.done : TimelineState.pending,
    ));

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x21000000)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: FieldifyColors.ink3,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++)
            _TimelineItem(entry: entries[i], isLast: i == entries.length - 1),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEntry entry;
  final bool isLast;
  const _TimelineItem({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _Dot(state: entry.state),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: entry.state == TimelineState.done
                        ? FieldifyColors.g800
                        : const Color(0x21000000),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    entry.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight:
                          entry.state == TimelineState.pending ? FontWeight.w400 : FontWeight.w500,
                      color: entry.state == TimelineState.pending
                          ? FieldifyColors.ink4
                          : entry.state == TimelineState.cancelled
                              ? const Color(0xFFC0392B)
                              : FieldifyColors.ink,
                    ),
                  ),
                  if (entry.sub != null && entry.sub!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.sub!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: FieldifyColors.ink3,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final TimelineState state;
  const _Dot({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case TimelineState.done:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: FieldifyColors.g800,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: FieldifyColors.g100, size: 14),
        );
      case TimelineState.active:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: FieldifyColors.g100,
            shape: BoxShape.circle,
            border: Border.all(color: FieldifyColors.g800, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: FieldifyColors.g800,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case TimelineState.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x21000000), width: 2),
          ),
        );
      case TimelineState.cancelled:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF0EF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC0392B), width: 2),
          ),
          child: const Icon(Icons.close, color: Color(0xFFC0392B), size: 14),
        );
    }
  }
}
