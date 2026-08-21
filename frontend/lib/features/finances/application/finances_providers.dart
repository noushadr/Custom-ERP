import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/finances_remote_data_source.dart';
import '../data/repositories/finances_repository_impl.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/financial_summary.dart';
import '../domain/repositories/finances_repository.dart';

final financesRemoteDataSourceProvider = Provider<FinancesRemoteDataSource>(
  (ref) => FinancesRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final financesRepositoryProvider = Provider<FinancesRepository>(
  (ref) => FinancesRepositoryImpl(ref.watch(financesRemoteDataSourceProvider)),
);

final financialSummaryProvider = FutureProvider.autoDispose
    .family<FinancialSummary, ({String? from, String? to})>((ref, range) {
      ref.watch(authControllerProvider);
      return ref
          .watch(financesRepositoryProvider)
          .getSummary(from: range.from, to: range.to);
    });

final expensesListProvider = FutureProvider.autoDispose
    .family<List<Expense>, ({String? from, String? to})>((ref, range) {
      ref.watch(authControllerProvider);
      return ref
          .watch(financesRepositoryProvider)
          .getExpenses(from: range.from, to: range.to);
    });
