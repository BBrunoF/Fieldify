import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/bottom_nav.dart';
import '../../../../auth/presentation/widgets/auth_shared.dart';
import '../../../../home/presentation/widgets/home_action_buttons.dart';
import '../../../jobs/controllers/pro_jobs_controller.dart';
import '../../../jobs/presentation/widgets/pro_jobs_view.dart';
import '../../../profile/presentation/screens/pro_profile_screen.dart';

class ProHomeScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;
  final ProJobsController? jobsController;

  const ProHomeScreen({
    super.key,
    this.onLogout,
    this.jobsController,
  });

  @override
  State<ProHomeScreen> createState() => _ProHomeScreenState();
}

class _ProHomeScreenState extends State<ProHomeScreen> {
  int _selectedNav = 0;

  void _onNavTap(int i) {
    if (i == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProProfileScreen()),
      );
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
    return Column(
      key: const Key('homeMainTab'),
      children: [
        Container(
          color: FieldifyColors.g800,
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
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
                'Welcome back,',
                key: const Key('homeGreetingText'),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: FieldifyColors.g200,
                ),
              ),
              Text(
                'Pro',
                key: const Key('homeUserNameText'),
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.72,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_outlined,
                    size: 56,
                    color: Colors.black.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your pro dashboard is on the way.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: FieldifyColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Head to the Jobs tab to see incoming requests.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: FieldifyColors.ink4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobsTab() {
    return Column(
      key: const Key('homeJobsTab'),
      children: [
        Container(
          color: FieldifyColors.g800,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
          child: Row(
            children: [
              Text(
                'Jobs',
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
            color: FieldifyColors.surface,
            child: ProJobsView(controller: widget.jobsController),
          ),
        ),
      ],
    );
  }
}
