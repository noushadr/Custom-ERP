import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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

/// Create/edit a single month's financial record. USD figures are never
/// typed directly — they're computed live as Rs ÷ FX Rate and shown
/// read-only, then sent to the backend as numeric strings (not JSON
/// numbers) alongside the typed Rs/FX-rate figures, matching
/// `FinancialRecord`'s TypeORM `numeric` columns and the DTOs'
/// `@IsNumberString()` validation. Once a record exists, its month/year
/// can't be changed — editing only touches the money fields, so there's no
/// month/year picker in edit mode at all.
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
  late final TextEditingController _expenseRsController;
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
    _expenseRsController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.expenseRs),
    );
    _fxRateController = TextEditingController(
      text: existing == null ? '' : _trimmed(existing.fxRate),
    );
    // Recomputes the taken-months warning (year) and the live computed USD
    // figures (revenue/expense/FX rate) as the user types — a plain
    // TextEditingController doesn't trigger a rebuild on its own.
    _yearController.addListener(_refresh);
    _revenueRsController.addListener(_refresh);
    _expenseRsController.addListener(_refresh);
    _fxRateController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  /// Drops a trailing ".0" so a whole-number figure doesn't show a
  /// pointless decimal when the editor opens for an existing record.
  String _trimmed(double value) =>
      value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  void dispose() {
    _yearController.removeListener(_refresh);
    _yearController.dispose();
    _revenueRsController.removeListener(_refresh);
    _revenueRsController.dispose();
    _expenseRsController.removeListener(_refresh);
    _expenseRsController.dispose();
    _fxRateController.removeListener(_refresh);
    _fxRateController.dispose();
    super.dispose();
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return double.tryParse(value.trim()) == null ? 'Must be a number' : null;
  }

  String? _fxRateValidator(String? value) {
    final plain = _numberValidator(value);
    if (plain != null) return plain;
    return double.parse(value!.trim()) <= 0 ? 'Must be greater than 0' : null;
  }

  /// Rs ÷ FX rate, rounded to the nearest whole unit — `null` until both
  /// inputs parse (including a non-zero FX rate).
  String? _computedUsd(String rsText, String fxRateText) {
    final rs = double.tryParse(rsText.trim());
    final fxRate = double.tryParse(fxRateText.trim());
    if (rs == null || fxRate == null || fxRate == 0) return null;
    return (rs / fxRate).round().toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final revenueRs = _revenueRsController.text.trim();
    final expenseRs = _expenseRsController.text.trim();
    final fxRate = _fxRateController.text.trim();
    final revenueUsd = _computedUsd(revenueRs, fxRate)!;
    final expenseUsd = _computedUsd(expenseRs, fxRate)!;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(financialReportsRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateRecord(
              widget.existingRecord!.id,
              revenueRs: revenueRs,
              revenueUsd: revenueUsd,
              expenseRs: expenseRs,
              expenseUsd: expenseUsd,
              fxRate: fxRate,
            )
          : await repository.createRecord(
              year: int.parse(_yearController.text.trim()),
              month: _month,
              revenueRs: revenueRs,
              revenueUsd: revenueUsd,
              expenseRs: expenseRs,
              expenseUsd: expenseUsd,
              fxRate: fxRate,
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
    // Month/year can never change once a record exists, so the taken-months
    // computation below only ever matters while creating a new one — still
    // cheap to compute unconditionally, just to keep this simple.
    final takenMonths = _takenMonths();
    final isDuplicate = !_isEditing && takenMonths.contains(_month);

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
                    if (_isEditing) ...[
                      Text(
                        '${_kMonthNames[_month - 1]} ${widget.existingRecord!.year}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "The month and year can't be changed after a record "
                        'is created.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
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
                          'A record for ${_kMonthNames[_month - 1]} '
                          '${_yearController.text.trim()} already exists — '
                          'edit it from the Monthly Detail table instead of '
                          'creating another one.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _fxRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'FX Rate (PKR per USD)',
                        helperText: 'Used to compute the USD figures below '
                            'automatically.',
                      ),
                      validator: _fxRateValidator,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: _ComputedUsdField(
                            label: 'Revenue (USD)',
                            value: _computedUsd(
                              _revenueRsController.text,
                              _fxRateController.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: _ComputedUsdField(
                            label: 'Expense (USD)',
                            value: _computedUsd(
                              _expenseRsController.text,
                              _fxRateController.text,
                            ),
                          ),
                        ),
                      ],
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

  /// Every other month/year already on file for the typed year — "every
  /// other" so editing a record doesn't flag its own current month as
  /// taken. Backed by the same uniqueness the server enforces
  /// (`POST /financial-records` 409s on a duplicate) — this is a proactive
  /// warning on top of that, not a replacement for it. Only meaningful in
  /// create mode; see the [_isEditing] guard in [build].
  Set<int> _takenMonths() {
    final records = ref.watch(financialRecordsListProvider).value ?? const [];
    final year = int.tryParse(_yearController.text.trim());
    if (year == null) return const {};
    return {
      for (final r in records)
        if (r.year == year && r.id != widget.existingRecord?.id) r.month,
    };
  }
}

/// A field-styled, read-only display for a USD figure computed from its
/// paired Rs field and the FX rate — never directly editable, per this
/// module's "USD is derived, not entered" rule.
class _ComputedUsdField extends StatelessWidget {
  const _ComputedUsdField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        enabled: false,
        filled: true,
        fillColor: AppColors.fieldFill,
      ),
      child: Text(
        value ?? '—',
        style: TextStyle(color: Theme.of(context).disabledColor),
      ),
    );
  }
}
