import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/pro_jobs_controller.dart';
import 'accepted_jobs_view.dart';
import 'incoming_jobs_view.dart';

enum ProJobsTab { incoming, accepted }

class ProJobsView extends StatefulWidget {
  final ProJobsController? controller;

  const ProJobsView({super.key, this.controller});

  @override
  State<ProJobsView> createState() => _ProJobsViewState();
}

class _ProJobsViewState extends State<ProJobsView> {
  ProJobsTab _selected = ProJobsTab.incoming;
  bool _acceptedTabMounted = false;
  int _incomingRefreshKey = 0;

  void _select(ProJobsTab tab) {
    if (_selected == tab) return;
    setState(() {
      _selected = tab;
      if (tab == ProJobsTab.accepted) {
        _acceptedTabMounted = true;
      }
    });
  }

  Future<void> _refreshIncomingJobs() async {
    final controller = widget.controller;
    if (controller != null) {
      await controller.loadIncomingJobs();
      return;
    }
    setState(() {
      _incomingRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('proJobsView'),
      children: [
        _ProJobsTabBar(selected: _selected, onChanged: _select),
        Expanded(
          child: Container(
            color: FieldifyColors.surface,
            child: IndexedStack(
              index: _selected.index,
              children: [
                IncomingJobsView(
                  key: ValueKey('incomingJobsView_$_incomingRefreshKey'),
                  controller: widget.controller,
                ),
                if (_acceptedTabMounted)
                  AcceptedJobsView(
                    controller: widget.controller,
                    onJobReturnedToIncoming: _refreshIncomingJobs,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProJobsTabBar extends StatelessWidget {
  final ProJobsTab selected;
  final ValueChanged<ProJobsTab> onChanged;

  const _ProJobsTabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          _ProJobsTabItem(
            label: 'Incoming',
            active: selected == ProJobsTab.incoming,
            onTap: () => onChanged(ProJobsTab.incoming),
            tabKey: const Key('proJobsTabIncoming'),
          ),
          const SizedBox(width: 32),
          _ProJobsTabItem(
            label: 'Accepted',
            active: selected == ProJobsTab.accepted,
            onTap: () => onChanged(ProJobsTab.accepted),
            tabKey: const Key('proJobsTabAccepted'),
          ),
        ],
      ),
    );
  }
}

class _ProJobsTabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Key tabKey;

  const _ProJobsTabItem({
    required this.label,
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
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : FieldifyColors.g200,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 48,
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
