/// Aggregated metrics shown on the pro home dashboard.
class ProDashboardStats {
  final double earningsThisMonth;
  final double earningsLastMonth;
  final int jobsCompletedAllTime;
  final int jobsCompletedThisMonth;
  final double ratingAverage;
  final int ratingCount;

  /// Accepted ÷ (accepted + rejected) over the last 30 days, in `0..1`.
  /// Null when there were no accept/reject events in the window.
  final double? acceptanceRate;

  const ProDashboardStats({
    required this.earningsThisMonth,
    required this.earningsLastMonth,
    required this.jobsCompletedAllTime,
    required this.jobsCompletedThisMonth,
    required this.ratingAverage,
    required this.ratingCount,
    required this.acceptanceRate,
  });

  static const empty = ProDashboardStats(
    earningsThisMonth: 0,
    earningsLastMonth: 0,
    jobsCompletedAllTime: 0,
    jobsCompletedThisMonth: 0,
    ratingAverage: 0,
    ratingCount: 0,
    acceptanceRate: null,
  );

  /// Rounded month-over-month earnings change as a percentage, or null when
  /// last month had no earnings (so the "+X% vs last month" line is hidden).
  int? get earningsChangePercent {
    if (earningsLastMonth <= 0) return null;
    return (((earningsThisMonth - earningsLastMonth) / earningsLastMonth) * 100)
        .round();
  }
}
