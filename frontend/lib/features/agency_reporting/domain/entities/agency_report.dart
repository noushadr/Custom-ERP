class AgencyReportProjectsByStatus {
  const AgencyReportProjectsByStatus({
    required this.active,
    required this.onHold,
    required this.completed,
    required this.cancelled,
  });

  final int active;
  final int onHold;
  final int completed;
  final int cancelled;
}

class AgencyReportClientProfit {
  const AgencyReportClientProfit({
    required this.clientId,
    required this.clientName,
    required this.profit,
  });

  final String clientId;
  final String clientName;
  final double profit;
}

/// A company-wide reporting snapshot over [from, to] — mirrors the backend's
/// AgencyReportDto. Every figure except [activeMonthlyRecurringRevenue] (a
/// live snapshot) is scoped to projects starting within the range.
class AgencyReport {
  const AgencyReport({
    required this.from,
    required this.to,
    required this.totalRevenue,
    required this.totalCost,
    required this.netProfit,
    required this.activeMonthlyRecurringRevenue,
    required this.oneTimeRevenue,
    required this.activeClientsCount,
    required this.newClientsCount,
    required this.lostClientsCount,
    required this.projectsByStatus,
    required this.topClientsByProfit,
  });

  final String from;
  final String to;
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final double activeMonthlyRecurringRevenue;
  final double oneTimeRevenue;
  final int activeClientsCount;
  final int newClientsCount;
  final int lostClientsCount;
  final AgencyReportProjectsByStatus projectsByStatus;
  final List<AgencyReportClientProfit> topClientsByProfit;
}
