class ProjectsSummary {
  const ProjectsSummary({
    required this.activeCount,
    required this.onHoldCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  final int activeCount;
  final int onHoldCount;
  final int completedCount;
  final int cancelledCount;
}
