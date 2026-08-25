import '../../domain/entities/financial_record.dart';

class FinancialRecordModel extends FinancialRecord {
  const FinancialRecordModel({
    required super.id,
    required super.year,
    required super.month,
    required super.revenueRs,
    required super.revenueUsd,
    required super.expenseRs,
    required super.expenseUsd,
    required super.fxRate,
    required super.profitRs,
    required super.profitUsd,
    required super.profitPercent,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FinancialRecordModel.fromJson(Map<String, dynamic> json) =>
      FinancialRecordModel(
        id: json['id'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        revenueRs: (json['revenueRs'] as num).toDouble(),
        revenueUsd: (json['revenueUsd'] as num).toDouble(),
        expenseRs: (json['expenseRs'] as num).toDouble(),
        expenseUsd: (json['expenseUsd'] as num).toDouble(),
        fxRate: (json['fxRate'] as num).toDouble(),
        profitRs: (json['profitRs'] as num).toDouble(),
        profitUsd: (json['profitUsd'] as num).toDouble(),
        profitPercent: (json['profitPercent'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
