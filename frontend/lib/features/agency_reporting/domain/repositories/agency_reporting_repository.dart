import '../entities/agency_report.dart';

abstract interface class AgencyReportingRepository {
  Future<AgencyReport> getReport({String? from, String? to});
}
