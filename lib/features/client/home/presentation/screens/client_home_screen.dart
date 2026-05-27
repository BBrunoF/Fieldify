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
import '../../../request/presentation/screens/request_screen.dart';
import '../../../../shared/chat/presentation/screens/inbox_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;
  final WidgetBuilder? requestScreenBuilder;
  final JobHistoryController? jobHistoryController;
  final ProfileController? profileController;

  const ClientHomeScreen({
    super.key,
    this.onLogout,
    this.requestScreenBuilder,
    this.jobHistoryController,
    this.profileController,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedCategory = 0;
  int _selectedNav = 0;
  late final ProfileController _profileController;
  late final bool _ownsProfileController;

  final LocationService _locationService = GeolocatorLocationService();
  LatLng _center = kDefaultLocation;

  @override
  void initState() {
    super.initState();
    _profileController = widget.profileController ?? ProfileController();
    _ownsProfileController = widget.profileController == null;
    _profileController.addListener(_onProfileChanged);
    _locationService.currentPosition().then((pos) {
      if (pos != null && mounted) setState(() => _center = pos);
    });
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

  void _openRequestFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: widget.requestScreenBuilder ?? (_) => const RequestScreen(),
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
              children: [_buildHeader(), _buildMap(), _buildSearchBar()],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: FieldifyColors.g800,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
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
                            Text(
                              'Porto, Portugal',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: FieldifyColors.g100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FieldifyColors.g200),
                        ),
                        child: Text(
                          '8 pros nearby',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FieldifyColors.g800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: FieldifyColors.ink3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'What do you need fixed?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: FieldifyColors.ink3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: FieldifyColors.g100,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Filter',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.g800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    const categories = [
      _CategoryData('Plumbing', ServiceIconType.plumbing),
      _CategoryData('Electrical', ServiceIconType.electrical),
      _CategoryData('Carpentry', ServiceIconType.carpentry),
      _CategoryData('HVAC', ServiceIconType.hvac),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ActiveJobBanner(),
          const SizedBox(height: 20),

          _SectionHeader(title: 'Services', link: 'See all', onLink: () {}),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _CategoryPill(
                  data: categories[i],
                  active: _selectedCategory == i,
                  onTap: () => setState(() => _selectedCategory = i),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          const _SectionHeader(title: 'Quick request'),
          const SizedBox(height: 12),
          _RequestCard(
            key: const Key('quickRequestPlumbingCard'),
            buttonKey: const Key('goToRequestButton'),
            onTap: _openRequestFlow,
            icon: ServiceIconType.plumbing,
            title: 'Plumbing',
            subtitle: 'Leaks, pipes, installations',
            time: '~12 min',
            price: 'from €30/h',
            filled: true,
          ),
          const SizedBox(height: 10),
          _RequestCard(
            onTap: _openRequestFlow,
            icon: ServiceIconType.electrical,
            title: 'Electrical',
            subtitle: 'Wiring, fuses, outlets',
            time: '~25 min',
            price: 'from €40/h',
            filled: false,
          ),
          const SizedBox(height: 10),
          _RequestCard(
            onTap: _openRequestFlow,
            icon: ServiceIconType.carpentry,
            title: 'Carpentry',
            subtitle: 'Furniture, doors, repairs',
            time: '~40 min',
            price: 'from €35/h',
            filled: false,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActiveJobBanner extends StatelessWidget {
  const _ActiveJobBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldifyColors.g800,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FieldifyColors.g700,
              shape: BoxShape.circle,
              border: Border.all(color: FieldifyColors.g200, width: 2),
            ),
            child: Center(
              child: Text(
                'MF',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: FieldifyColors.g100,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE JOB',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.g200,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pipe leak repair',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Manuel F. · On the way · ~8 min',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: FieldifyColors.g200,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FieldifyColors.g200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF173404),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? link;
  final VoidCallback? onLink;

  const _SectionHeader({required this.title, this.link, this.onLink});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: FieldifyColors.ink2,
            letterSpacing: -0.13,
          ),
        ),
        if (link != null)
          GestureDetector(
            onTap: onLink,
            child: Text(
              link!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.g700,
              ),
            ),
          ),
      ],
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

class _RequestCard extends StatelessWidget {
  final ServiceIconType icon;
  final String title;
  final String subtitle;
  final String time;
  final String price;
  final bool filled;
  final Key? buttonKey;
  final VoidCallback onTap;

  const _RequestCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.price,
    required this.filled,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: FieldifyColors.g100,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: ServiceIconPainter(
                  icon: icon,
                  color: FieldifyColors.g800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FieldifyColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: FieldifyColors.ink3,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: FieldifyColors.g700,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                        color: FieldifyColors.ink4,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: FieldifyColors.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: buttonKey,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: filled ? FieldifyColors.g800 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: filled
                    ? null
                    : Border.all(color: FieldifyColors.g200, width: 1.5),
              ),
              child: Text(
                'Request',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: filled ? FieldifyColors.g100 : FieldifyColors.g800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
