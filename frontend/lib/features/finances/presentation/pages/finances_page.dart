import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/finances_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/financial_summary.dart';
import '../../domain/exceptions/finances_exception.dart';
import '../widgets/expense_category_label.dart';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTimeRange _thisMonthRange(DateTime now) =>
    DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

DateTimeRange _lastMonthRange(DateTime now) {
  final lastMonthEnd = DateTime(
    now.year,
    now.month,
    1,
  ).subtract(const Duration(days: 1));
  return DateTimeRange(
    start: DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
    end: lastMonthEnd,
  );
}

DateTimeRange _thisYearRange(DateTime now) =>
    DateTimeRange(start: DateTime(now.year, 1, 1), end: now);

DateTimeRange _lastYearRange(DateTime now) => DateTimeRange(
  start: DateTime(now.year - 1, 1, 1),
  end: DateTime(now.year - 1, 12, 31),
);

/// Company-wide P&L dashboard — Super-Admin-only: gated by nav visibility in
/// main.dart, by `finances.manage` on the backend routes, and by its own
/// `hasPermission` check at the top of `build()` below (so this page's data
/// providers are never even watched for an unauthorized viewer, regardless
/// of nav — see `AccessDeniedView`'s doc comment for why that matters).
class FinancesPage extends ConsumerStatefulWidget {
  const FinancesPage({super.key});

  @override
  ConsumerState<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends ConsumerState<FinancesPage> {
  late String _presetLabel;
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    _presetLabel = 'This Month';
    _range = _thisMonthRange(DateTime.now());
  }

  void _selectPreset(String label, DateTimeRange range) {
    setState(() {
      _presetLabel = label;
      _range = range;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() {
      _presetLabel = 'Custom';
      _range = picked;
    });
  }

  ({String? from, String? to}) get _rangeArgs =>
      (from: _isoDate(_range.start), to: _isoDate(_range.end));

  void _refresh() {
    ref.invalidate(financialSummaryProvider(_rangeArgs));
    ref.invalidate(expensesListProvider(_rangeArgs));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('finances.manage')) {
      return const AccessDeniedView();
    }

    final summaryAsync = ref.watch(financialSummaryProvider(_rangeArgs));
    final expensesAsync = ref.watch(expensesListProvider(_rangeArgs));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RangeControls(
                  now: DateTime.now(),
                  presetLabel: _presetLabel,
                  range: _range,
                  onSelectPreset: _selectPreset,
                  onPickCustom: _pickCustomRange,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 20),
                summaryAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Text(
                    'Could not load the financial summary. Please try again.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (summary) => _SummaryBody(summary: summary),
                ),
                const SizedBox(height: 20),
                FormSection(
                  title: 'Expenses',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await showDialog<void>(
                              context: context,
                              builder: (_) => const _ExpenseDialog(),
                            );
                            _refresh();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Expense'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      expensesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => Text(
                          'Could not load expenses. Please try again.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        data: (expenses) => _ExpensesList(
                          expenses: expenses,
                          onEdited: _refresh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeControls extends StatelessWidget {
  const _RangeControls({
    required this.now,
    required this.presetLabel,
    required this.range,
    required this.onSelectPreset,
    required this.onPickCustom,
    required this.onRefresh,
  });

  final DateTime now;
  final String presetLabel;
  final DateTimeRange range;
  final void Function(String label, DateTimeRange range) onSelectPreset;
  final VoidCallback onPickCustom;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('This Month'),
          selected: presetLabel == 'This Month',
          onSelected: (_) => onSelectPreset('This Month', _thisMonthRange(now)),
        ),
        ChoiceChip(
          label: const Text('Last Month'),
          selected: presetLabel == 'Last Month',
          onSelected: (_) => onSelectPreset('Last Month', _lastMonthRange(now)),
        ),
        ChoiceChip(
          label: const Text('This Year'),
          selected: presetLabel == 'This Year',
          onSelected: (_) => onSelectPreset('This Year', _thisYearRange(now)),
        ),
        ChoiceChip(
          label: const Text('Last Year'),
          selected: presetLabel == 'Last Year',
          onSelected: (_) => onSelectPreset('Last Year', _lastYearRange(now)),
        ),
        OutlinedButton.icon(
          onPressed: onPickCustom,
          icon: const Icon(Icons.date_range, size: 16),
          label: Text(
            presetLabel == 'Custom'
                ? '${formatDisplayDate(_isoDate(range.start))} – ${formatDisplayDate(_isoDate(range.end))}'
                : 'Custom range',
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatTile(
              label: 'Gross Revenue',
              value: 'PKR ${formatWholeAmount(summary.grossRevenue)}',
              color: AppColors.primary,
              icon: Icons.payments_outlined,
            ),
            _StatTile(
              label: 'Deductions',
              value: 'PKR ${formatWholeAmount(summary.deductions)}',
              color: AppColors.warning,
              icon: Icons.remove_circle_outline,
            ),
            _StatTile(
              label: 'Project Costs',
              value: 'PKR ${formatWholeAmount(summary.projectCosts)}',
              color: AppColors.warning,
              icon: Icons.money_off_outlined,
            ),
            _StatTile(
              label: 'Total Expenses',
              value: 'PKR ${formatWholeAmount(summary.totalExpenses)}',
              color: AppColors.error,
              icon: Icons.receipt_long_outlined,
            ),
            _StatTile(
              label: 'Net Profit',
              value: 'PKR ${formatWholeAmount(summary.netProfit)}',
              color: AppColors.success,
              icon: Icons.trending_up,
            ),
            _StatTile(
              label: 'Current Monthly Payroll',
              value: 'PKR ${formatWholeAmount(summary.currentMonthlyPayroll)}',
              color: AppColors.secondary,
              icon: Icons.groups_outlined,
            ),
            _StatTile(
              label: 'Outstanding Invoices',
              value: 'PKR ${formatWholeAmount(summary.outstandingInvoicesTotal)}',
              secondaryValue: '${summary.outstandingInvoicesCount} project(s)',
              color: AppColors.accentTeal,
              icon: Icons.request_quote_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        FormSection(
          title: 'Expenses by Category',
          child: summary.expensesByCategory.isEmpty
              ? Text(
                  'No expenses recorded in this range yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in summary.expensesByCategory.entries)
                      Chip(
                        label: Text(
                          '${formatExpenseCategoryLabel(entry.key)}: PKR ${formatWholeAmount(entry.value)}',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList({required this.expenses, required this.onEdited});

  final List<Expense> expenses;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return Text(
        'No expenses recorded in this range yet.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < expenses.length; i++) ...[
          _ExpenseRow(
            expense: expenses[i],
            onTap: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => _ExpenseDialog(expense: expenses[i]),
              );
              onEdited();
            },
          ),
          if (i < expenses.length - 1)
            const Divider(height: 16, color: AppColors.borderSubtle),
        ],
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                formatExpenseCategoryLabel(expense.category),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                expense.payeeName ?? '—',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                formatDisplayDate(expense.date),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Text(
              'PKR ${formatAmount(expense.amount)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.secondaryValue,
  });

  final String label;
  final String value;
  final String? secondaryValue;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondaryValue != null)
            Text(
              secondaryValue!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDialog extends ConsumerStatefulWidget {
  const _ExpenseDialog({this.expense});

  final Expense? expense;

  @override
  ConsumerState<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends ConsumerState<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late final TextEditingController _amountController;
  late final TextEditingController _payeeController;
  late final TextEditingController _notesController;
  late DateTime _date;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _category = expense?.category ?? ExpenseCategory.other;
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _payeeController = TextEditingController(text: expense?.payeeName ?? '');
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _date = expense == null ? DateTime.now() : DateTime.parse(expense.date);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(financesRepositoryProvider);
      final amount = double.parse(_amountController.text);
      final date = _isoDate(_date);
      final payeeName = _payeeController.text.trim().isEmpty
          ? null
          : _payeeController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      if (_isEditing) {
        await repository.updateExpense(
          widget.expense!.id,
          category: _category,
          amount: amount,
          date: date,
          payeeName: payeeName,
          notes: notes,
        );
      } else {
        await repository.createExpense(
          category: _category,
          amount: amount,
          date: date,
          payeeName: payeeName,
          notes: notes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FinancesException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
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
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in ExpenseCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(formatExpenseCategoryLabel(category)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _category = value);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (PKR)'),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter an amount greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _saving ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(formatDisplayDate(_isoDate(_date))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _payeeController,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Payee (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                enabled: !_saving,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
