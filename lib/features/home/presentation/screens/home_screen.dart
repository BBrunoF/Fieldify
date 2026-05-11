import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../client/home/presentation/screens/client_home_screen.dart';
import '../../../client/job_history/controllers/job_history_controller.dart';
import '../../../pro/home/presentation/screens/pro_home_screen.dart';
import '../../../pro/jobs/controllers/pro_jobs_controller.dart';
import '../../controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  final Future<bool> Function()? loadProfessionalRole;
  final Future<void> Function()? onLogout;
  final WidgetBuilder? requestScreenBuilder;
  final ProJobsController? proJobsController;
  final JobHistoryController? jobHistoryController;
  final HomeController? homeController;

  const HomeScreen({
    super.key,
    this.loadProfessionalRole,
    this.onLogout,
    this.requestScreenBuilder,
    this.proJobsController,
    this.jobHistoryController,
    this.homeController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _isProfessional;
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = widget.homeController ?? HomeController();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final isProfessional = widget.loadProfessionalRole != null
          ? await widget.loadProfessionalRole!()
          : await _homeController.loadIsProfessional();
      if (!mounted) return;
      setState(() => _isProfessional = isProfessional);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfessional = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfessional == null) {
      return const Scaffold(
        backgroundColor: FieldifyColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isProfessional!) {
      return ProHomeScreen(
        onLogout: widget.onLogout,
        jobsController: widget.proJobsController,
      );
    }

    return ClientHomeScreen(
      onLogout: widget.onLogout,
      requestScreenBuilder: widget.requestScreenBuilder,
      jobHistoryController: widget.jobHistoryController,
    );
  }
}
