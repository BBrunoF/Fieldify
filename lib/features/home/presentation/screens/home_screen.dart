import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/auth_shared.dart';
import '../../../../shared/widgets/fieldify_painters.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../client/request/presentation/screens/request_screen.dart';
import '../../../pro/incoming_jobs/presentation/widgets/incoming_jobs_view.dart';

// ── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;
  int _selectedNav = 0;
  bool _isProfessional = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final isProfessional = profile != null && profile['role'] == 'professional';
      if (!mounted) return;
      setState(() {
        _isProfessional = isProfessional;
        if (!_isProfessional && _selectedNav == 1) {
          _selectedNav = 0;
        }
      });
    } catch (_) {}
  }

  void _onNavTap(int i) {
    if (!_isProfessional && i == 1) {
      setState(() => _selectedNav = 0);
      return;
    }
    setState(() => _selectedNav = i);
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
          showJobs: _isProfessional,
        ),
        body: SafeArea(
          bottom: false,
          child: _selectedNav == 1 && _isProfessional
              ? _buildJobsTab()
              : _buildMainTab(),
        ),
      ),
    );
  }


  Widget _buildMainTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Green zone: header + map + search ──────────────────────
          Container(
            color: FieldifyColors.g800,
            child: Column(
              children: [
                _buildHeader(),
                _buildMap(),
                _buildSearchBar(),
              ],
            ),
          ),
          // ── Curved transition strip ────────────────────────────────
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
          // ── Body content ───────────────────────────────────────────
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return Column(
      children: [
        Container(
          color: FieldifyColors.g800,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
          child: Row(
            children: [
              Text(
                'Incoming jobs',
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
            color: FieldifyColors.surface,
            child: const IncomingJobsView(),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
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
                    child: Center(
                      child: CustomPaint(
                        size: const Size(18, 18),
                        painter: FieldifyMarkPainter(),
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
                children: const [
                  const _NotifButton(),
                  SizedBox(width: 8),
                  _LogoutButton(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Good morning,',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: FieldifyColors.g200,
            ),
          ),
          // TODO: replace with current user name from profile
          Text(
            'Bruno',
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

  // ── Map strip ──────────────────────────────────────────────────────────────
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
                child: CustomPaint(painter: MapPainter()),
              ),
              // TODO: replace pro dot initials with nearby pros from DB
              const Positioned(top: 18, left: 45, child: _ProDot('MF')),
              const Positioned(top: 62, right: 45, child: _ProDot('AC')),
              const Positioned(bottom: 22, left: 70, child: _ProDot('JR')),
              // Center pin
              const Center(child: MapPin()),
              // Bottom overlay
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
                            horizontal: 11, vertical: 5),
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
                            // TODO: replace with user location from profile/GPS
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
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FieldifyColors.g200),
                        ),
                        // TODO: replace with live nearby pros count from DB
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

  // ── Search bar ─────────────────────────────────────────────────────────────
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
                    fontSize: 14, color: FieldifyColors.ink3),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

  // ── Body content ───────────────────────────────────────────────────────────
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
          // Active job banner
          const _ActiveJobBanner(),
          const SizedBox(height: 20),

          // Services
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

          // Quick request
          const _SectionHeader(title: 'Quick request'),
          const SizedBox(height: 12),
          _RequestCard(
            key: Key('goToRequestButton'),
            icon: ServiceIconType.plumbing,
            title: 'Plumbing',
            subtitle: 'Leaks, pipes, installations',
            time: '~12 min',
            price: 'from €30/h',
            filled: true,
          ),
          const SizedBox(height: 10),
          _RequestCard(
            icon: ServiceIconType.electrical,
            title: 'Electrical',
            subtitle: 'Wiring, fuses, outlets',
            time: '~25 min',
            price: 'from €40/h',
            filled: false,
          ),
          const SizedBox(height: 10),
          _RequestCard(
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

// ── Small widgets ─────────────────────────────────────────────────────────────

class _NotifButton extends StatelessWidget {
  const _NotifButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withAlpha(51), width: 1.5),
          ),
          child: const Icon(Icons.notifications_outlined,
              size: 16, color: FieldifyColors.g100),
        ),
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: FieldifyColors.g200,
              shape: BoxShape.circle,
              border: Border.all(color: FieldifyColors.g800, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}


class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await supabase.auth.signOut();
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.logout_rounded,
            size: 16,
            color: FieldifyColors.g100,
          ),
        ),
      ),
    );
  }
}

class _ProDot extends StatelessWidget {
  final String initials;
  const _ProDot(this.initials);


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: FieldifyColors.g700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.dmSans(
            fontSize: 6,
            fontWeight: FontWeight.w500,
            color: FieldifyColors.g100,
          ),
        ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

// ── Category pill ─────────────────────────────────────────────────────────────

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
                color: active
                    ? FieldifyColors.g800
                    : const Color(0x14000000),
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

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ServiceIconType icon;
  final String title;
  final String subtitle;
  final String time;
  final String price;
  final bool filled;

  const _RequestCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.price,
    required this.filled,
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
          // Icon box
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
          // Info
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
                      fontSize: 12, color: FieldifyColors.ink3),
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
                          fontSize: 11, color: FieldifyColors.ink3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Button
          GestureDetector(
            key: const Key('goToRequestButton'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: filled ? FieldifyColors.g800 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: filled
                    ? null
                    : Border.all(
                        color: FieldifyColors.g200, width: 1.5),
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
