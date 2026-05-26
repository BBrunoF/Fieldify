import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/pro_dashboard_controller.dart';
import '../../data/models/pro_dashboard_stats.dart';

class ProDashboardView extends StatelessWidget {
  final ProDashboardController controller;

  const ProDashboardView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Center(
            key: Key('dashboardLoading'),
            child: CircularProgressIndicator(),
          );
        }
        return _buildGrid(controller.stats);
      },
    );
  }

  Widget _buildGrid(ProDashboardStats stats) {
    final changePercent = stats.earningsChangePercent;

    return SingleChildScrollView(
      key: const Key('dashboardGrid'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('statEarnings'),
                  label: 'This month',
                  value: '€${stats.earningsThisMonth.round()}',
                  subtitle: changePercent == null
                      ? null
                      : '${changePercent >= 0 ? '+' : ''}$changePercent% vs last month',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  key: const Key('statJobsCompleted'),
                  label: 'Jobs completed',
                  value: '${stats.jobsCompletedAllTime}',
                  subtitle: '${stats.jobsCompletedThisMonth} this month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('statRating'),
                  label: 'Your rating',
                  value: stats.ratingCount == 0
                      ? '—'
                      : stats.ratingAverage.toStringAsFixed(1),
                  subtitle: stats.ratingCount == 0
                      ? 'No reviews yet'
                      : 'based on ${stats.ratingCount} review${stats.ratingCount == 1 ? '' : 's'}',
                  muted: stats.ratingCount == 0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  key: const Key('statAcceptance'),
                  label: 'Acceptance rate',
                  value: stats.acceptanceRate == null
                      ? '—'
                      : '${(stats.acceptanceRate! * 100).round()}%',
                  subtitle: 'Last 30 days',
                  muted: stats.acceptanceRate == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  /// When true, the subtitle is rendered in a neutral grey (empty states like
  /// "No reviews yet") rather than the accent green.
  final bool muted;

  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FieldifyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: FieldifyColors.ink3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: FieldifyColors.ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: muted ? FieldifyColors.ink3 : FieldifyColors.g500,
              ),
            )
          else
            const SizedBox(height: 15),
        ],
      ),
    );
  }
}
