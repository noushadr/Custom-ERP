import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/payroll_remote_data_source.dart';
import '../data/repositories/payroll_repository_impl.dart';
import '../domain/entities/payroll_run_detail.dart';
import '../domain/entities/payroll_run_summary.dart';
import '../domain/repositories/payroll_repository.dart';

final payrollRemoteDataSourceProvider = Provider<PayrollRemoteDataSource>(
  (ref) => PayrollRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final payrollRepositoryProvider = Provider<PayrollRepository>(
  (ref) => PayrollRepositoryImpl(ref.watch(payrollRemoteDataSourceProvider)),
);

final payrollRunsListProvider = FutureProvider.autoDispose<List<PayrollRunSummary>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(payrollRepositoryProvider).getRuns();
});

final payrollRunDetailProvider = FutureProvider.autoDispose
    .family<PayrollRunDetail, String>((ref, id) {
      ref.watch(authControllerProvider);
      return ref.watch(payrollRepositoryProvider).getRun(id);
    });
