import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/payroll_providers.dart';
import '../../domain/entities/payroll_run_summary.dart';
import '../../domain/exceptions/payroll_exception.dart';
import '../widgets/payroll_run_status_badge.dart';
import 'payroll_run_detail_page.dart';

/// List of every generated payroll run — shared by Super Admin and
/// HR/Manager (gated by nav visibility in main.dart, and by
/// `payroll.manage` on the backend routes).
class PayrollPage extends ConsumerWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('payroll.manage')) {
      return const AccessDeniedView();
    }

    final runsAsync = ref.watch(payrollRunsListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payroll Runs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => const _GeneratePayrollDialog(),
                      );
                      ref.invalidate(payrollRunsListProvider);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Generate Payroll'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: runsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(
                    'Could not load payroll runs. Please try again.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (runs) => runs.isEmpty
                      ? Center(
                          child: Text(
                            'No payroll runs generated yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: runs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _RunRow(run: runs[index]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final PayrollRunSummary run;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PayrollRunDetailPage(runId: run.id)),
        ),
        title: Text(formatPayrollRunPeriod(run.month, run.year)),
        subtitle: Text('${run.employeeCount} employee(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PKR ${formatAmount(run.totalNetPay)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            PayrollRunStatusBadge(status: run.status),
          ],
        ),
      ),
    );
  }
}

class _GeneratePayrollDialog extends ConsumerStatefulWidget {
  const _GeneratePayrollDialog();

  @override
  ConsumerState<_GeneratePayrollDialog> createState() =>
      _GeneratePayrollDialogState();
}

class _GeneratePayrollDialogState extends ConsumerState<_GeneratePayrollDialog> {
  late int _month;
  late int _year;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(payrollRepositoryProvider)
          .generateRun(month: _month, year: _year);
      if (mounted) Navigator.of(context).pop();
    } on PayrollException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('Generate Payroll'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(formatPayrollRunPeriod(m, _year).split(' ').first),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _month = value);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      for (var y = now.year - 2; y <= now.year + 1; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _year = value);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}
