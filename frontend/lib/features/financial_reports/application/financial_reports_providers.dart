import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/financial_reports_remote_data_source.dart';
import '../data/repositories/financial_reports_repository_impl.dart';
import '../domain/entities/financial_record.dart';
import '../domain/repositories/financial_reports_repository.dart';

final financialReportsRemoteDataSourceProvider =
    Provider<FinancialReportsRemoteDataSource>(
      (ref) =>
          FinancialReportsRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final financialReportsRepositoryProvider =
    Provider<FinancialReportsRepository>(
      (ref) => FinancialReportsRepositoryImpl(
        ref.watch(financialReportsRemoteDataSourceProvider),
      ),
    );

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final financialRecordsListProvider =
    FutureProvider.autoDispose<List<FinancialRecord>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(financialReportsRepositoryProvider).getRecords();
    });
