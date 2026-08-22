import '../../domain/entities/projects_summary.dart';

class ProjectsSummaryModel extends ProjectsSummary {
  const ProjectsSummaryModel({
    required super.activeCount,
    required super.onHoldCount,
    required super.completedCount,
    required super.cancelledCount,
    required super.activeMonthlyRecurringRevenue,
    required super.oneTimeRevenueThisYear,
  });

  factory ProjectsSummaryModel.fromJson(Map<String, dynamic> json) =>
      ProjectsSummaryModel(
        activeCount: json['activeCount'] as int,
        onHoldCount: json['onHoldCount'] as int,
        completedCount: json['completedCount'] as int,
        cancelledCount: json['cancelledCount'] as int,
        activeMonthlyRecurringRevenue:
            (json['activeMonthlyRecurringRevenue'] as num).toDouble(),
        oneTimeRevenueThisYear: (json['oneTimeRevenueThisYear'] as num)
            .toDouble(),
      );
}
