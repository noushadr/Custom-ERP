class ProjectsSummary {
  const ProjectsSummary({
    required this.activeCount,
    required this.onHoldCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.activeMonthlyRecurringRevenue,
    required this.oneTimeRevenueThisYear,
  });

  final int activeCount;
  final int onHoldCount;
  final int completedCount;
  final int cancelledCount;
  final double activeMonthlyRecurringRevenue;
  final double oneTimeRevenueThisYear;
}
