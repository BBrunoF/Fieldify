import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../data/models/job_detail_model.dart';

class ClientActionBar extends StatelessWidget {
  final JobDetail detail;
  final bool isBusy;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;
  final VoidCallback? onSubmitReview;
  final VoidCallback? onSubmitNewRequest;

  const ClientActionBar({
    super.key,
    required this.detail,
    required this.isBusy,
    this.onCancel,
    this.onMessage,
    this.onSubmitReview,
    this.onSubmitNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    switch (detail.status) {
      case JobStatus.pending:
        return _Bar([_danger('Cancel request', onCancel)]);
      case JobStatus.accepted:
      case JobStatus.onMyWay:
        return _Bar([
          _ghost('Message', onMessage),
          _danger(
            detail.status == JobStatus.onMyWay
                ? 'Cancel — fee applies'
                : 'Cancel job',
            onCancel,
          ),
        ]);
      case JobStatus.inProgress:
        return _Bar([_ghost('Message', onMessage)]);
      case JobStatus.completed:
        return _Bar([_primary('Submit review', onSubmitReview)]);
      case JobStatus.cancelled:
        return _Bar([_primary('Submit a new request', onSubmitNewRequest)]);
    }
  }

  Widget _primary(String label, VoidCallback? onTap) =>
      _ActionButton(label: label, onTap: onTap, kind: _Kind.primary, busy: isBusy);
  Widget _ghost(String label, VoidCallback? onTap) =>
      _ActionButton(label: label, onTap: onTap, kind: _Kind.ghost, busy: false);
  Widget _danger(String label, VoidCallback? onTap) =>
      _ActionButton(label: label, onTap: onTap, kind: _Kind.danger, busy: isBusy);
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

enum _Kind { primary, ghost, danger }

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
    Color bg;
    Color fg;
    BoxBorder? border;
    switch (kind) {
      case _Kind.primary:
        bg = FieldifyColors.g800;
        fg = FieldifyColors.g100;
        border = null;
        break;
      case _Kind.ghost:
        bg = Colors.transparent;
        fg = FieldifyColors.ink3;
        border = Border.all(color: const Color(0x21000000));
        break;
      case _Kind.danger:
        bg = Colors.transparent;
        fg = const Color(0xFFC0392B);
        border = Border.all(color: const Color(0xFFF5C6C6));
        break;
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: kind == _Kind.primary ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          alignment: Alignment.center,
          child: busy && kind != _Kind.ghost
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: kind == _Kind.primary ? 15 : 14,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}
