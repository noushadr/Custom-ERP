import '../../domain/entities/payslip_list_item.dart';

class PayslipListItemModel extends PayslipListItem {
  const PayslipListItemModel({
    required super.runId,
    required super.lineItemId,
    required super.month,
    required super.year,
    required super.netPay,
    required super.paidAt,
  });

  factory PayslipListItemModel.fromJson(Map<String, dynamic> json) =>
      PayslipListItemModel(
        runId: json['runId'] as String,
        lineItemId: json['lineItemId'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        netPay: (json['netPay'] as num).toDouble(),
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}
