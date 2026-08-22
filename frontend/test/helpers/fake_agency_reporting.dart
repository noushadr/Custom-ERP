import 'package:zera_erp/features/agency_reporting/domain/entities/agency_report.dart';
import 'package:zera_erp/features/agency_reporting/domain/repositories/agency_reporting_repository.dart';

AgencyReport buildTestAgencyReport({
  String from = '2026-08-01',
  String to = '2026-08-21',
  double totalRevenue = 0,
  double totalCost = 0,
  double netProfit = 0,
  double activeMonthlyRecurringRevenue = 0,
  double oneTimeRevenue = 0,
  int activeClientsCount = 0,
  int newClientsCount = 0,
  int lostClientsCount = 0,
  AgencyReportProjectsByStatus? projectsByStatus,
  List<AgencyReportClientProfit> topClientsByProfit = const [],
}) {
  return AgencyReport(
    from: from,
    to: to,
    totalRevenue: totalRevenue,
    totalCost: totalCost,
    netProfit: netProfit,
    activeMonthlyRecurringRevenue: activeMonthlyRecurringRevenue,
    oneTimeRevenue: oneTimeRevenue,
    activeClientsCount: activeClientsCount,
    newClientsCount: newClientsCount,
    lostClientsCount: lostClientsCount,
    projectsByStatus:
        projectsByStatus ??
        const AgencyReportProjectsByStatus(
          active: 0,
          onHold: 0,
          completed: 0,
          cancelled: 0,
        ),
    topClientsByProfit: topClientsByProfit,
  );
}

class FakeAgencyReportingRepository implements AgencyReportingRepository {
  FakeAgencyReportingRepository({this.report});

  final AgencyReport? report;

  String? lastFrom;
  String? lastTo;

  /// Incremented on every [getReport] call — used to confirm a refresh
  /// action actually re-fetched rather than reading a cached value.
  int callCount = 0;

  @override
  Future<AgencyReport> getReport({String? from, String? to}) async {
    callCount++;
    lastFrom = from;
    lastTo = to;
    return report ?? buildTestAgencyReport(from: from ?? '2026-08-01', to: to ?? '2026-08-21');
  }
}
