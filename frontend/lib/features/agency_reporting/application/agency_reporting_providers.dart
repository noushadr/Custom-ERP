import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/agency_reporting_remote_data_source.dart';
import '../data/repositories/agency_reporting_repository_impl.dart';
import '../domain/entities/agency_report.dart';
import '../domain/repositories/agency_reporting_repository.dart';

final agencyReportingRemoteDataSourceProvider =
    Provider<AgencyReportingRemoteDataSource>(
      (ref) => AgencyReportingRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final agencyReportingRepositoryProvider = Provider<AgencyReportingRepository>(
  (ref) => AgencyReportingRepositoryImpl(
    ref.watch(agencyReportingRemoteDataSourceProvider),
  ),
);

final agencyReportProvider = FutureProvider.autoDispose
    .family<AgencyReport, ({String? from, String? to})>((ref, range) {
      ref.watch(authControllerProvider);
      return ref
          .watch(agencyReportingRepositoryProvider)
          .getReport(from: range.from, to: range.to);
    });
