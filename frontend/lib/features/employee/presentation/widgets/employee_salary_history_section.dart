import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/salary_record.dart';
import '../../domain/exceptions/employee_exception.dart';

/// A single label + value line reused by the Work section for the "Joining
/// salary" and "Current salary" rows. Pass null for [employeeId] to show the
/// current user's own history; pass an id (requires `employees.manage`) for
/// another employee's.
class SalaryHeadlineValue extends ConsumerWidget {
  const SalaryHeadlineValue({
    super.key,
    this.employeeId,
    required this.which,
  });

  final String? employeeId;
  final SalaryHeadline which;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = employeeId == null
        ? ref.watch(mySalaryHistoryProvider)
        : ref.watch(employeeSalaryHistoryProvider(employeeId!));

    return historyAsync.when(
      loading: () => const Text('Loading…'),
      error: (_, _) => const Text('—'),
      data: (records) {
        if (records.isEmpty) return const Text('—');
        final record = which == SalaryHeadline.joining
            ? records.first
            : records.last;
        return Text(
          '${formatAmount(record.amount)} · effective '
          '${formatDisplayDate(record.effectiveDate)}',
        );
      },
    );
  }
}

enum SalaryHeadline { joining, current }

/// Full chronological salary history, with an "Add raise" action and
/// per-record delete when [canManage] is true. [employeeId] is always the
/// real employee id — writes never have a "me" equivalent, since granting
/// raises requires `employees.manage` even when viewing one's own profile.
/// Set [isSelf] to read via the self-service endpoints instead of the
/// `employees.manage`-gated ones.
class EmployeeSalaryHistorySection extends ConsumerStatefulWidget {
  const EmployeeSalaryHistorySection({
    super.key,
    required this.employeeId,
    required this.isSelf,
    required this.canManage,
  });

  final String employeeId;
  final bool isSelf;
  final bool canManage;

  @override
  ConsumerState<EmployeeSalaryHistorySection> createState() =>
      _EmployeeSalaryHistorySectionState();
}

class _EmployeeSalaryHistorySectionState
    extends ConsumerState<EmployeeSalaryHistorySection> {
  String? _deletingRecordId;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _invalidate() {
    ref.invalidate(employeeSalaryHistoryProvider(widget.employeeId));
    ref.invalidate(employeeAuditLogProvider(widget.employeeId));
    if (widget.isSelf) {
      ref.invalidate(mySalaryHistoryProvider);
      ref.invalidate(myAuditLogProvider);
    }
  }

  Future<void> _addRaise() async {
    final result = await showDialog<_AddRaiseResult>(
      context: context,
      builder: (_) => const _AddRaiseDialog(),
    );
    if (result == null) return;

    try {
      await ref
          .read(employeeRepositoryProvider)
          .addSalaryRecord(
            widget.employeeId,
            amount: result.amount,
            effectiveDate: result.effectiveDate,
            note: result.note,
          );
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _delete(SalaryRecord record) async {
    setState(() => _deletingRecordId = record.id);
    try {
      await ref
          .read(employeeRepositoryProvider)
          .deleteSalaryRecord(widget.employeeId, record.id);
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _deletingRecordId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = widget.isSelf
        ? ref.watch(mySalaryHistoryProvider)
        : ref.watch(employeeSalaryHistoryProvider(widget.employeeId));

    return FormSection(
      title: 'Salary History',
      child: historyAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load salary history.'),
        data: (records) {
          final reversed = records.reversed.toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (records.isEmpty)
                Text(
                  'No salary records yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (var i = 0; i < reversed.length; i++) ...[
                  _SalaryHistoryRow(
                    record: reversed[i],
                    label: i == reversed.length - 1
                        ? 'Joining salary'
                        : 'Raise',
                    isDeleting: _deletingRecordId == reversed[i].id,
                    onDelete: widget.canManage
                        ? () => _delete(reversed[i])
                        : null,
                  ),
                  if (i < reversed.length - 1)
                    const Divider(height: 20, color: AppColors.borderSubtle),
                ],
              if (widget.canManage) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addRaise,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add raise'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SalaryHistoryRow extends StatelessWidget {
  const _SalaryHistoryRow({
    required this.record,
    required this.label,
    required this.isDeleting,
    this.onDelete,
  });

  final SalaryRecord record;
  final String label;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label · ${formatAmount(record.amount)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Effective ${formatDisplayDate(record.effectiveDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    record.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    onPressed: onDelete,
                  ),
        ],
      ),
    );
  }
}

class _AddRaiseResult {
  const _AddRaiseResult({
    required this.amount,
    required this.effectiveDate,
    this.note,
  });

  final double amount;
  final String effectiveDate;
  final String? note;
}

class _AddRaiseDialog extends StatefulWidget {
  const _AddRaiseDialog();

  @override
  State<_AddRaiseDialog> createState() => _AddRaiseDialogState();
}

class _AddRaiseDialogState extends State<_AddRaiseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _effectiveDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _effectiveDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _AddRaiseResult(
        amount: double.parse(_amountController.text.trim()),
        effectiveDate: _isoDate(_effectiveDate),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add salary raise'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'New amount'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Effective date',
                ),
                child: Text(formatDisplayDate(_isoDate(_effectiveDate))),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
