import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/financial_reports_providers.dart';
import '../../domain/entities/financial_record.dart';
import '../../domain/exceptions/financial_record_exception.dart';

const _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Create/edit a single month's financial record. Revenue/expense/FX-rate
/// fields are sent to the backend as numeric strings (not JSON numbers) —
/// `FinancialRecord`'s columns are TypeORM `numeric`, validated server-side
/// with `@IsNumberString()`, so whatever the user typed is passed through
/// as-is once it's confirmed to parse.
class FinancialRecordEditorPage extends ConsumerStatefulWidget {
  const FinancialRecordEditorPage({super.key, this.existingRecord});

  /// Null when creating a new record; the current record when editing.
  final FinancialRecord? existingRecord;

  @override
  ConsumerState<FinancialRecordEditorPage> createState() =>
      _FinancialRecordEditorPageState();
}

class _FinancialRecordEditorPageState
    extends ConsumerState<FinancialRecordEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;
  late final TextEditingController _revenueRsController;
  late final TextEditingController _revenueUsdController;
  late final TextEditingController _expenseRsController;
  late final TextEditingController _expenseUsdController;
  late final TextEditingController _fxRateController;

  late int _month;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecord;
    _month = existing?.month ?? DateTime.now().month;
    _yearController = TextEditingController(
      text: '${existing?.year ?? DateTime.now().year}',
    );
    _revenueRsController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.revenueRs),
    );
    _revenueUsdController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.revenueUsd),
    );
    _expenseRsController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.expenseRs),
    );
    _expenseUsdController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.expenseUsd),
    );
    _fxRateController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.fxRate),
    );
    // Recomputes which months are already taken for the typed year as the
    // user edits it — a plain TextEditingController doesn't trigger a
    // rebuild on its own.
    _yearController.addListener(_onYearChanged);
  }

  void _onYearChanged() => setState(() {});

  /// Drops a trailing ".0" so a whole-number figure doesn't show a
  /// pointless decimal when the editor opens for an existing record.
  String _trimmed(double value) =>
      value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  void dispose() {
    _yearController.removeListener(_onYearChanged);
    _yearController.dispose();
    _revenueRsController.dispose();
    _revenueUsdController.dispose();
    _expenseRsController.dispose();
    _expenseUsdController.dispose();
    _fxRateController.dispose();
    super.dispose();
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return double.tryParse(value.trim()) == null ? 'Must be a number' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(financialReportsRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateRecord(
              widget.existingRecord!.id,
              year: int.parse(_yearController.text.trim()),
              month: _month,
              revenueRs: _revenueRsController.text.trim(),
              revenueUsd: _revenueUsdController.text.trim(),
              expenseRs: _expenseRsController.text.trim(),
              expenseUsd: _expenseUsdController.text.trim(),
              fxRate: _fxRateController.text.trim(),
            )
          : await repository.createRecord(
              year: int.parse(_yearController.text.trim()),
              month: _month,
              revenueRs: _revenueRsController.text.trim(),
              revenueUsd: _revenueUsdController.text.trim(),
              expenseRs: _expenseRsController.text.trim(),
              expenseUsd: _expenseUsdController.text.trim(),
              fxRate: _fxRateController.text.trim(),
            );

      ref.invalidate(financialRecordsListProvider);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on FinancialRecordException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(financialRecordsListProvider).value ?? const [];
    final year = int.tryParse(_yearController.text.trim());
    // Every other month/year already on file for the typed year — "every
    // other" so editing a record doesn't flag its own current month as
    // taken. Backed by the same uniqueness the server enforces
    // (`POST /financial-records` 409s on a duplicate) — this is a
    // proactive warning on top of that, not a replacement for it.
    final takenMonths = year == null
        ? const <int>{}
        : {
            for (final r in records)
              if (r.year == year && r.id != widget.existingRecord?.id) r.month,
          };
    final isDuplicate = takenMonths.contains(_month);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Financial Record' : 'New Financial Record'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _month,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                            ),
                            items: [
                              for (var m = 1; m <= 12; m++)
                                DropdownMenuItem(
                                  enabled: !takenMonths.contains(m),
                                  value: m,
                                  child: Text(
                                    takenMonths.contains(m)
                                        ? '${_kMonthNames[m - 1]} (already added)'
                                        : _kMonthNames[m - 1],
                                    style: takenMonths.contains(m)
                                        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).disabledColor,
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _month = value ?? _month),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                            ),
                            validator: (value) {
                              final year = int.tryParse(value?.trim() ?? '');
                              if (year == null) return 'Must be a number';
                              return (year < 2000 || year > 2100)
                                  ? 'Enter a valid year'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (isDuplicate) ...[
                      const SizedBox(height: 8),
                      Text(
                        'A record for ${_kMonthNames[_month - 1]} $year already '
                        'exists — edit it from the Monthly Detail table '
                        'instead of creating another one.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _revenueRsController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Revenue (Rs)',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _revenueUsdController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Revenue (USD)',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expenseRsController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Expense (Rs)',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _expenseUsdController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Expense (USD)',
                            ),
                            validator: _numberValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fxRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'FX Rate (PKR per USD)',
                        helperText: 'Reference only — revenue/expense in '
                            "both currencies are entered directly, not "
                            'derived from this rate.',
                      ),
                      validator: _numberValidator,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: (_submitting || isDuplicate) ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Create Record'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
