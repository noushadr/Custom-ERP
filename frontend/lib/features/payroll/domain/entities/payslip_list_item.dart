/// One row of the caller's own "My Payslips" list — always a Paid run's
/// own employee line item.
class PayslipListItem {
  const PayslipListItem({
    required this.runId,
    required this.lineItemId,
    required this.month,
    required this.year,
    required this.netPay,
    required this.paidAt,
  });

  final String runId;
  final String lineItemId;
  final int month;
  final int year;
  final double netPay;
  final DateTime paidAt;
}
