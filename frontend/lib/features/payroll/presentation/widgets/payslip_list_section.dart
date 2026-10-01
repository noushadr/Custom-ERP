import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/utils/file_download/file_download.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/payroll_providers.dart';
import '../../domain/entities/payslip_list_item.dart';
import '../../domain/exceptions/payroll_exception.dart';
import 'payroll_run_status_badge.dart';

/// A "Payslips" `FormSection` listing every Paid-run period in [payslipsAsync]
/// with a download button each — shared by the User Dashboard's own "My
/// Payslips" section and the Employee Profile page's HR/Admin-facing
/// Payslips section, which differ only in which provider feeds them and
/// whether the download goes through the self-service or the HR/Admin
/// download route.
class PayslipListSection extends ConsumerWidget {
  const PayslipListSection({
    super.key,
    required this.title,
    required this.payslipsAsync,
    required this.emptyMessage,
    required this.downloadPayslip,
  });

  final String title;
  final AsyncValue<List<PayslipListItem>> payslipsAsync;
  final String emptyMessage;

  /// Fetches the given payslip's PDF bytes — the self-service `/mine`
  /// route on the Dashboard, or the HR/Admin `runId`/`lineItemId` route on
  /// the Employee Profile page.
  final Future<List<int>> Function(WidgetRef ref, PayslipListItem payslip)
  downloadPayslip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormSection(
      title: title,
      child: payslipsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (error, _) => Text(
          error is PayrollException
              ? error.message
              : 'Could not load payslips.',
        ),
        data: (payslips) {
          if (payslips.isEmpty) {
            return Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < payslips.length; i++) ...[
                _PayslipRow(
                  payslip: payslips[i],
                  onDownload: () async {
                    try {
                      final bytes = await downloadPayslip(ref, payslips[i]);
                      downloadBytes(
                        bytes,
                        'Payslip-${payslips[i].year}-'
                        '${payslips[i].month.toString().padLeft(2, '0')}.pdf',
                      );
                    } on PayrollException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                ),
                if (i < payslips.length - 1)
                  const Divider(height: 4, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PayslipRow extends StatelessWidget {
  const _PayslipRow({required this.payslip, required this.onDownload});

  final PayslipListItem payslip;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            formatPayrollRunPeriod(payslip.month, payslip.year),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          'PKR ${formatAmount(payslip.netPay)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, size: 18),
          tooltip: 'Download payslip',
          onPressed: onDownload,
        ),
      ],
    );
  }
}

/// The Dashboard's own "My Payslips" instance — self-service download route.
class MyPayslipsSection extends ConsumerWidget {
  const MyPayslipsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PayslipListSection(
      title: 'My Payslips',
      payslipsAsync: ref.watch(myPayslipsProvider),
      emptyMessage:
          'No payslips yet — one appears here once a payroll run '
          'covering you is marked Paid.',
      downloadPayslip: (ref, payslip) => ref
          .read(payrollRepositoryProvider)
          .downloadMyPayslip(payslip.lineItemId),
    );
  }
}

/// The Employee Profile page's HR/Admin-facing instance — the HR/Admin
/// `runId`/`lineItemId` download route, since the viewer isn't downloading
/// their own payslip.
class EmployeePayslipsSection extends ConsumerWidget {
  const EmployeePayslipsSection({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PayslipListSection(
      title: 'Payslips',
      payslipsAsync: ref.watch(employeePayslipsProvider(employeeId)),
      emptyMessage:
          'No payslips yet — one appears here once a payroll run '
          'covering this employee is marked Paid.',
      downloadPayslip: (ref, payslip) => ref
          .read(payrollRepositoryProvider)
          .downloadPayslip(payslip.runId, payslip.lineItemId),
    );
  }
}
