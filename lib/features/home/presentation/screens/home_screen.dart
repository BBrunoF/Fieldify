import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../client/home/presentation/screens/client_home_screen.dart';
import '../../../client/job_history/controllers/job_history_controller.dart';
import '../../../pro/home/presentation/screens/pro_home_screen.dart';
import '../../../pro/incoming_jobs/controllers/incoming_jobs_controller.dart';

class HomeScreen extends StatefulWidget {
  final Future<bool> Function()? loadProfessionalRole;
  final Future<void> Function()? onLogout;
  final WidgetBuilder? requestScreenBuilder;
  final IncomingJobsController? incomingJobsController;
  final JobHistoryController? jobHistoryController;

  const HomeScreen({
    super.key,
    this.loadProfessionalRole,
    this.onLogout,
    this.requestScreenBuilder,
    this.incomingJobsController,
    this.jobHistoryController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _isProfessional;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final isProfessional = widget.loadProfessionalRole != null
          ? await widget.loadProfessionalRole!()
          : await _fetchProfessionalRoleFromSupabase();
      if (!mounted) return;
      setState(() => _isProfessional = isProfessional);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfessional = false);
    }
  }

  Future<bool> _fetchProfessionalRoleFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final profile = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return profile != null && profile['role'] == 'professional';
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
        incomingJobsController: widget.incomingJobsController,
      );
    }

    return ClientHomeScreen(
      onLogout: widget.onLogout,
      requestScreenBuilder: widget.requestScreenBuilder,
      jobHistoryController: widget.jobHistoryController,
    );
  }
}
