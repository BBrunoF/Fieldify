import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/location/location_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shared/location/data/location_service.dart';
import '../../../../shared/location/presentation/static_map_view.dart';
import '../../../../../shared/widgets/bottom_nav.dart';
import '../../../../../shared/widgets/fieldify_painters.dart';
import '../../../../home/presentation/widgets/home_action_buttons.dart';
import '../../../job_history/controllers/job_history_controller.dart';
import '../../../job_history/presentation/widgets/job_history_view.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../request/data/models/trade_model.dart';
import '../../../request/data/repositories/request_repository.dart';
import '../../../request/presentation/screens/request_screen.dart';
import '../../../request/presentation/trade_icon_mapper.dart';
import '../../../../shared/chat/presentation/screens/inbox_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;
  final WidgetBuilder? requestScreenBuilder;
  final JobHistoryController? jobHistoryController;
  final ProfileController? profileController;
  final RequestRepository? tradesRepository;

  const ClientHomeScreen({
    super.key,
    this.onLogout,
    this.requestScreenBuilder,
    this.jobHistoryController,
    this.profileController,
    this.tradesRepository,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedNav = 0;
  late final ProfileController _profileController;
  late final bool _ownsProfileController;

  late final RequestRepository _tradesRepo;
  List<Trade> _trades = const [];
  bool _loadingTrades = true;
  String? _tradesError;

  final LocationService _locationService = GeolocatorLocationService();
  LatLng _center = kDefaultLocation;
  String? _locationLabel;

  @override
  void initState() {
    super.initState();
    _profileController = widget.profileController ?? ProfileController();
    _ownsProfileController = widget.profileController == null;
    _profileController.addListener(_onProfileChanged);
    _tradesRepo = widget.tradesRepository ?? RequestRepository();
    _loadTrades();
    _loadLocation();
  }

  Future<void> _loadTrades() async {
    try {
      final trades = await _tradesRepo.getTrades();
      if (!mounted) return;
      setState(() {
        _trades = trades;
        _loadingTrades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tradesError = 'Could not load services.';
        _loadingTrades = false;
      });
    }
  }

  Future<void> _loadLocation() async {
    final pos = await _locationService.currentPosition();
    if (pos == null || !mounted) return;
    setState(() => _center = pos);
    final label = await _locationService.addressFor(pos.latitude, pos.longitude);
    if (label != null && mounted) setState(() => _locationLabel = label);
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileController.removeListener(_onProfileChanged);
    if (_ownsProfileController) _profileController.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InboxScreen()),
      );
      return;
    }
    if (i == 3) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
          .then((_) => _profileController.reload());
      return;
    }
    setState(() => _selectedNav = i);
  }

  void _openRequestFlow([Trade? trade]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: widget.requestScreenBuilder ??
            (_) => RequestScreen(initialTradeId: trade?.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: FieldifyColors.g800,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FieldifyColors.surface,
        bottomNavigationBar: BottomNav(
          selected: _selectedNav,
          onTap: _onNavTap,
          showJobs: true,
        ),
        body: SafeArea(
          bottom: false,
          child: _selectedNav == 1 ? _buildJobsTab() : _buildMainTab(),
        ),
      ),
    );
  }

  Widget _buildMainTab() {
    return SingleChildScrollView(
      key: const Key('homeMainTab'),
      child: Column(
        children: [
          Container(
            color: FieldifyColors.g800,
            child: Column(
              children: [_buildHeader(), _buildMap()],
            ),
          ),
          Container(
            height: 18,
            color: FieldifyColors.g800,
            child: Container(
              decoration: const BoxDecoration(
                color: FieldifyColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return Column(
      key: const Key('homeJobsTab'),
      children: [
        Container(
          color: FieldifyColors.g800,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
          child: Row(
            children: [
              Text(
                'My jobs',
                key: const Key('homeJobsHeader'),
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: FieldifyColors.g800,
            child: JobHistoryView(controller: widget.jobHistoryController),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: FieldifyColors.g100,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/icon/mark.png',
                        color: FieldifyColors.g800,
                        colorBlendMode: BlendMode.srcIn,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fieldify',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.34,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const NotifButton(),
                  const SizedBox(width: 8),
                  LogoutButton(onLogout: widget.onLogout),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Good morning,',
            key: const Key('homeGreetingText'),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: FieldifyColors.g200,
            ),
          ),
          Text(
            _profileController.profile?.firstName.isNotEmpty == true
                ? _profileController.profile!.firstName
                : 'there',
            key: const Key('homeUserNameText'),
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.72,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(
                child: StaticMapView(position: _center, height: 160),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _locationLabel == null
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: FieldifyColors.g800,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: FieldifyColors.g200,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _locationLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: FieldifyColors.g100,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'What do you need fixed?'),
          const SizedBox(height: 12),
          _buildTrades(),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('goToRequestButton'),
            onPressed: _openRequestFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: FieldifyColors.g800,
              foregroundColor: FieldifyColors.g100,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Request a job',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.g100,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTrades() {
    if (_loadingTrades) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tradesError != null || _trades.isEmpty) {
      return Text(
        _tradesError ?? 'No services available right now.',
        style: GoogleFonts.dmSans(fontSize: 13, color: FieldifyColors.ink3),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: [
        for (final trade in _trades)
          KeyedSubtree(
            key: Key('homeTradeTile_${trade.id}'),
            child: _CategoryPill(
              data: _CategoryData(trade.displayName, iconForTrade(trade.slug)),
              active: false,
              onTap: () => _openRequestFlow(trade),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: FieldifyColors.ink2,
        letterSpacing: -0.13,
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final ServiceIconType icon;
  const _CategoryData(this.name, this.icon);
}

class _CategoryPill extends StatelessWidget {
  final _CategoryData data;
  final bool active;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active ? FieldifyColors.g800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? FieldifyColors.g800 : const Color(0x14000000),
              ),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: ServiceIconPainter(
                  icon: data.icon,
                  color: active ? FieldifyColors.g100 : FieldifyColors.g800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.name,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: active ? FieldifyColors.g800 : FieldifyColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
