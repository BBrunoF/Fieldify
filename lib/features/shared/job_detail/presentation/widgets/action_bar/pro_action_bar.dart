import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../data/models/job_detail_model.dart';

class ProActionBar extends StatelessWidget {
  final JobDetail detail;
  final bool isBusy;
  final VoidCallback? onMessage;
  final VoidCallback? onMarkOnTheWay;
  final VoidCallback? onMarkInProgress;
  final VoidCallback? onMarkCompleted;

  const ProActionBar({
    super.key,
    required this.detail,
    required this.isBusy,
    this.onMessage,
    this.onMarkOnTheWay,
    this.onMarkInProgress,
    this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    switch (detail.status) {
      case JobStatus.pending:
        return _Bar([_ghost('Waiting for system…', null)]);
      case JobStatus.accepted:
        return _Bar([
          _ghost('Message client', onMessage),
          _primary('Start heading over', onMarkOnTheWay),
        ]);
      case JobStatus.onMyWay:
        return _Bar([
          _ghost('Message client', onMessage),
          _primary("I've arrived — start job", onMarkInProgress),
        ]);
      case JobStatus.inProgress:
        return _Bar([
          _ghost('Message client', onMessage),
          _primary('Mark job complete', onMarkCompleted),
        ]);
      case JobStatus.completed:
      case JobStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _primary(String label, VoidCallback? onTap) =>
      _ActionButton(label: label, onTap: onTap, kind: _Kind.primary, busy: isBusy);
  Widget _ghost(String label, VoidCallback? onTap) =>
      _ActionButton(label: label, onTap: onTap, kind: _Kind.ghost, busy: false);
}

class _Bar extends StatelessWidget {
  final List<Widget> children;
  const _Bar(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

enum _Kind { primary, ghost }

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final _Kind kind;
  final bool busy;
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.kind,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final isPrimary = kind == _Kind.primary;
    final bg = isPrimary ? FieldifyColors.g800 : Colors.transparent;
    final fg = isPrimary ? FieldifyColors.g100 : FieldifyColors.ink3;
    final border = isPrimary
        ? null
        : Border.all(color: const Color(0x21000000));

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isPrimary ? 14 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          alignment: Alignment.center,
          child: busy && isPrimary
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(FieldifyColors.g100),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: isPrimary ? 15 : 14,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}
