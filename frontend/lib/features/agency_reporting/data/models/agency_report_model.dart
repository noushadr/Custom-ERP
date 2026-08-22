import '../../domain/entities/agency_report.dart';

class AgencyReportModel extends AgencyReport {
  const AgencyReportModel({
    required super.from,
    required super.to,
    required super.totalRevenue,
    required super.totalCost,
    required super.netProfit,
    required super.activeMonthlyRecurringRevenue,
    required super.oneTimeRevenue,
    required super.activeClientsCount,
    required super.newClientsCount,
    required super.lostClientsCount,
    required super.projectsByStatus,
    required super.topClientsByProfit,
  });

  factory AgencyReportModel.fromJson(Map<String, dynamic> json) {
    final statusJson = json['projectsByStatus'] as Map<String, dynamic>;
    final topClientsJson = json['topClientsByProfit'] as List<dynamic>;

    return AgencyReportModel(
      from: json['from'] as String,
      to: json['to'] as String,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
      activeMonthlyRecurringRevenue: (json['activeMonthlyRecurringRevenue'] as num)
          .toDouble(),
      oneTimeRevenue: (json['oneTimeRevenue'] as num).toDouble(),
      activeClientsCount: json['activeClientsCount'] as int,
      newClientsCount: json['newClientsCount'] as int,
      lostClientsCount: json['lostClientsCount'] as int,
      projectsByStatus: AgencyReportProjectsByStatus(
        active: statusJson['active'] as int,
        onHold: statusJson['onHold'] as int,
        completed: statusJson['completed'] as int,
        cancelled: statusJson['cancelled'] as int,
      ),
      topClientsByProfit: topClientsJson
          .cast<Map<String, dynamic>>()
          .map(
            (entry) => AgencyReportClientProfit(
              clientId: entry['clientId'] as String,
              clientName: entry['clientName'] as String,
              profit: (entry['profit'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
