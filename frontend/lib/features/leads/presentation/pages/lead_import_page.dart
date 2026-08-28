import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead_import_row.dart';
import '../../domain/exceptions/lead_exception.dart';

const _kImportMonthAbbreviations = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// Fixed column order the paste box expects — matches `_kLeadColumns` on
/// [LeadsPage] so a user copying straight out of that table (or the
/// spreadsheet it was itself imported from) lines up without remapping.
const _kImportColumnOrder = [
  'Date',
  'Full Name',
  'Company',
  'Phone',
  'Email',
  'Country',
  'Service Interested',
  'Lead Source',
  'Remarks',
];

/// One parsed line from the paste box: either a ready-to-send [row], or an
/// [error] explaining why it was skipped. Never both.
class ParsedImportRow {
  const ParsedImportRow({required this.raw, this.row, this.error});

  final List<String> raw;
  final LeadImportRow? row;
  final String? error;

  bool get isValid => row != null;

  /// The full-name cell, for display in the preview list — falls back to a
  /// row index label when even that couldn't be read.
  String displayName(int index) =>
      (raw.length > 1 && raw[1].isNotEmpty) ? raw[1] : 'Row ${index + 1}';
}

/// Splits pasted text into rows (newline-separated) and cells
/// (tab-separated), in the fixed [_kImportColumnOrder]. Blank lines are
/// skipped entirely rather than reported as errors, since trailing blank
/// lines are the norm when pasting from a spreadsheet.
List<ParsedImportRow> parseImportText(String text) {
  final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
  return [for (final line in lines) _parseImportLine(line)];
}

ParsedImportRow _parseImportLine(String line) {
  final cells = line.split('\t').map((cell) => cell.trim()).toList();
  String? cell(int index) =>
      (index < cells.length && cells[index].isNotEmpty) ? cells[index] : null;

  final fullName = cell(1);
  if (fullName == null) {
    return ParsedImportRow(raw: cells, error: 'Missing full name');
  }

  final dateRaw = cell(0);
  if (dateRaw == null) {
    return ParsedImportRow(raw: cells, error: 'Missing date');
  }
  final isoDate = _tryParseDate(dateRaw);
  if (isoDate == null) {
    return ParsedImportRow(raw: cells, error: 'Unrecognized date "$dateRaw"');
  }

  return ParsedImportRow(
    raw: cells,
    row: LeadImportRow(
      leadDate: isoDate,
      fullName: fullName,
      companyName: cell(2),
      phone: cell(3),
      email: cell(4),
      country: cell(5),
      serviceInterested: cell(6),
      leadSource: cell(7),
      remarks: cell(8),
    ),
  );
}

/// Tries ISO-ish formats first (`DateTime.tryParse` covers `yyyy-MM-dd` and
/// friends), then falls back to the "MMM D, YYYY" shape (e.g. "Jul 15,
/// 2026") used by every real lead dataset imported into this app so far.
String? _tryParseDate(String raw) {
  final direct = DateTime.tryParse(raw);
  if (direct != null) return _isoDate(direct);

  final match = RegExp(
    r'^([A-Za-z]{3,})\s+(\d{1,2}),?\s+(\d{4})$',
  ).firstMatch(raw);
  if (match == null) return null;

  final monthIndex = _kImportMonthAbbreviations.indexOf(
    match.group(1)!.toLowerCase().substring(0, 3),
  );
  final day = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (monthIndex == -1 || day == null || year == null) return null;

  final parsed = DateTime(year, monthIndex + 1, day);
  // Guards against e.g. "Feb 30, 2026" silently rolling over into March.
  if (parsed.month != monthIndex + 1 || parsed.day != day) return null;
  return _isoDate(parsed);
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Bulk-import entry point for the Leads module: paste tab-separated rows
/// (as copied out of Excel/Google Sheets) in a fixed column order, preview
/// which parsed cleanly, then send only the valid rows in one request. No
/// deduplication — every valid row becomes a new lead, matching how every
/// past real-data batch has been imported into this app.
class LeadImportPage extends ConsumerStatefulWidget {
  const LeadImportPage({super.key});

  @override
  ConsumerState<LeadImportPage> createState() => _LeadImportPageState();
}

class _LeadImportPageState extends ConsumerState<LeadImportPage> {
  final _textController = TextEditingController();
  List<ParsedImportRow> _parsed = const [];
  bool _importing = false;
  String? _errorMessage;
  int? _importedCount;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _parsed = parseImportText(text);
      _importedCount = null;
      _errorMessage = null;
    });
  }

  Future<void> _submit(List<LeadImportRow> validRows) async {
    setState(() {
      _importing = true;
      _errorMessage = null;
    });

    final repository = ref.read(leadsRepositoryProvider);
    try {
      final created = await repository.importLeads(validRows);
      ref.invalidate(leadsListProvider);
      if (!mounted) return;
      setState(() => _importedCount = created);
    } on LeadException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validRows = [
      for (final row in _parsed)
        if (row.row != null) row.row!,
    ];
    final errorCount = _parsed.length - validRows.length;
    final imported = _importedCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Leads')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: imported != null
                  ? [_ImportSuccessCard(count: imported)]
                  : [
                      _ImportInstructions(errorMessage: _errorMessage),
                      const SizedBox(height: 16),
                      FormSection(
                        title: 'Paste leads',
                        child: TextField(
                          controller: _textController,
                          onChanged: _onTextChanged,
                          maxLines: 10,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Paste tab-separated rows here…',
                          ),
                        ),
                      ),
                      if (_parsed.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ImportPreview(parsed: _parsed, errorCount: errorCount),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: (validRows.isEmpty || _importing)
                              ? null
                              : () => _submit(validRows),
                          icon: _importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined, size: 18),
                          label: Text(
                            _importing
                                ? 'Importing…'
                                : 'Import ${validRows.length} Lead${validRows.length == 1 ? '' : 's'}',
                          ),
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

class _ImportInstructions extends StatelessWidget {
  const _ImportInstructions({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste rows copied from Excel or Google Sheets — one lead per line, '
          'columns in this order: ${_kImportColumnOrder.join(', ')}. '
          'Date and Full Name are required; leave any other cell blank if it '
          "doesn't apply.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _ImportPreview extends StatelessWidget {
  const _ImportPreview({required this.parsed, required this.errorCount});

  final List<ParsedImportRow> parsed;
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    final validCount = parsed.length - errorCount;
    return FormSection(
      title: 'Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${parsed.length} row${parsed.length == 1 ? '' : 's'} found — '
            '$validCount ready to import'
            '${errorCount > 0 ? ', $errorCount with errors (skipped)' : ''}.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: parsed.length,
              itemBuilder: (context, index) {
                final row = parsed[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    row.isValid
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: row.isValid ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  title: Text(row.displayName(index)),
                  subtitle: row.isValid
                      ? null
                      : Text(
                          row.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSuccessCard extends StatelessWidget {
  const _ImportSuccessCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Imported $count lead${count == 1 ? '' : 's'}.'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
