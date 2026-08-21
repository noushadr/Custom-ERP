import 'package:dio/dio.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_summary.dart';
import '../../domain/exceptions/finances_exception.dart';
import '../../domain/repositories/finances_repository.dart';
import '../datasources/finances_remote_data_source.dart';

class FinancesRepositoryImpl implements FinancesRepository {
  const FinancesRepositoryImpl(this._remoteDataSource);

  final FinancesRemoteDataSource _remoteDataSource;

  @override
  Future<FinancialSummary> getSummary({String? from, String? to}) =>
      _guard(() => _remoteDataSource.getSummary(from: from, to: to));

  @override
  Future<List<Expense>> getExpenses({String? from, String? to}) =>
      _guard(() => _remoteDataSource.getExpenses(from: from, to: to));

  @override
  Future<Expense> createExpense({
    required String category,
    required double amount,
    required String date,
    String? payeeName,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.createExpense(
      category: category,
      amount: amount,
      date: date,
      payeeName: payeeName,
      notes: notes,
    ),
  );

  @override
  Future<Expense> updateExpense(
    String id, {
    String? category,
    double? amount,
    String? date,
    String? payeeName,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.updateExpense(
      id,
      category: category,
      amount: amount,
      date: date,
      payeeName: payeeName,
      notes: notes,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw FinancesException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
