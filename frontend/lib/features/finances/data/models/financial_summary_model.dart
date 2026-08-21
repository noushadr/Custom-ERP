import '../../domain/entities/financial_summary.dart';

class FinancialSummaryModel extends FinancialSummary {
  const FinancialSummaryModel({
    required super.from,
    required super.to,
    required super.grossRevenue,
    required super.deductions,
    required super.projectCosts,
    required super.totalExpenses,
    required super.expensesByCategory,
    required super.netProfit,
    required super.currentMonthlyPayroll,
    required super.outstandingInvoicesTotal,
    required super.outstandingInvoicesCount,
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['expensesByCategory'] as Map<String, dynamic>;
    return FinancialSummaryModel(
      from: json['from'] as String,
      to: json['to'] as String,
      grossRevenue: (json['grossRevenue'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      projectCosts: (json['projectCosts'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      expensesByCategory: categoryJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      netProfit: (json['netProfit'] as num).toDouble(),
      currentMonthlyPayroll: (json['currentMonthlyPayroll'] as num).toDouble(),
      outstandingInvoicesTotal: (json['outstandingInvoicesTotal'] as num)
          .toDouble(),
      outstandingInvoicesCount: json['outstandingInvoicesCount'] as int,
    );
  }
}
