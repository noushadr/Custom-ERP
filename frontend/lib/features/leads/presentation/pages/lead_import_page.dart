import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
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
/// [error] explaining why it was skipped. Never both. A valid row can also
/// carry a [duplicateReason] — set by [flagDuplicates], never by parsing
/// itself, since checking for duplicates needs the already-loaded list of
/// existing leads that the parser has no access to.
class ParsedImportRow {
  const ParsedImportRow({
    required this.raw,
    this.row,
    this.error,
    this.duplicateReason,
  });

  final List<String> raw;
  final LeadImportRow? row;
  final String? error;
  final String? duplicateReason;

  bool get isValid => row != null;
  bool get isDuplicate => duplicateReason != null;

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

/// Flags each valid row in [rows] whose phone or email (normalized) matches
/// either an existing lead already in the system or an earlier row in this
/// same paste — a soft, informational check rather than a hard block. Rows
/// with neither phone nor email can't be checked and are never flagged. An
/// existing-lead match is checked before a within-batch match so the
/// reported reason always points at the more useful match when both apply.
List<ParsedImportRow> flagDuplicates(
  List<ParsedImportRow> rows,
  List<Lead> existingLeads,
) {
  final existingPhones = <String, Lead>{};
  final existingEmails = <String, Lead>{};
  for (final lead in existingLeads) {
    final phoneKey = _normalizedPhoneKey(lead.phone);
    if (phoneKey != null) existingPhones.putIfAbsent(phoneKey, () => lead);
    final emailKey = _normalizedEmailKey(lead.email);
    if (emailKey != null) existingEmails.putIfAbsent(emailKey, () => lead);
  }

  final seenPhones = <String, int>{};
  final seenEmails = <String, int>{};

  final result = <ParsedImportRow>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (!row.isValid) {
      result.add(row);
      continue;
    }

    final phoneKey = _normalizedPhoneKey(row.row!.phone);
    final emailKey = _normalizedEmailKey(row.row!.email);
    String? reason;

    if (phoneKey != null && existingPhones.containsKey(phoneKey)) {
      reason =
          'Same phone as existing lead "${existingPhones[phoneKey]!.fullName}"';
    } else if (emailKey != null && existingEmails.containsKey(emailKey)) {
      reason =
          'Same email as existing lead "${existingEmails[emailKey]!.fullName}"';
    } else if (phoneKey != null && seenPhones.containsKey(phoneKey)) {
      reason = 'Same phone as row ${seenPhones[phoneKey]! + 1} above';
    } else if (emailKey != null && seenEmails.containsKey(emailKey)) {
      reason = 'Same email as row ${seenEmails[emailKey]! + 1} above';
    }

    if (phoneKey != null) seenPhones.putIfAbsent(phoneKey, () => i);
    if (emailKey != null) seenEmails.putIfAbsent(emailKey, () => i);

    result.add(
      ParsedImportRow(raw: row.raw, row: row.row, duplicateReason: reason),
    );
  }
  return result;
}

/// Strips everything but digits so formatting differences ("+1 555-0100" vs
/// "15550100") don't hide a real match — purely a comparison key, never
/// stored or displayed.
String? _normalizedPhoneKey(String? phone) {
  if (phone == null) return null;
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : digits;
}

String? _normalizedEmailKey(String? email) {
  final trimmed = email?.trim().toLowerCase();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
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
/// which parsed cleanly, then send only the valid, non-duplicate rows in one
/// request. A row is flagged as a possible duplicate — and excluded from the
/// import by default — when its phone or email matches an existing lead
/// already in the system, or an earlier row in the same paste (see
/// [flagDuplicates]); the preview lets the user check a flagged row to
/// import it anyway, e.g. two different people who share a household phone.
class LeadImportPage extends ConsumerStatefulWidget {
  const LeadImportPage({super.key});

  @override
  ConsumerState<LeadImportPage> createState() => _LeadImportPageState();
}

class _LeadImportPageState extends ConsumerState<LeadImportPage> {
  final _textController = TextEditingController();
  List<ParsedImportRow> _parsed = const [];
  final Set<int> _includedDespiteDuplicate = {};
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
      _includedDespiteDuplicate.clear();
      _importedCount = null;
      _errorMessage = null;
    });
  }

  void _toggleDuplicate(int index) {
    setState(() {
      if (!_includedDespiteDuplicate.remove(index)) {
        _includedDespiteDuplicate.add(index);
      }
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
    final existingLeads = ref.watch(leadsListProvider).value ?? const <Lead>[];
    final flagged = flagDuplicates(_parsed, existingLeads);

    final validRows = [
      for (var i = 0; i < flagged.length; i++)
        if (flagged[i].isValid &&
            (!flagged[i].isDuplicate || _includedDespiteDuplicate.contains(i)))
          flagged[i].row!,
    ];
    final errorCount = flagged.where((row) => !row.isValid).length;
    final duplicateCount = flagged.where((row) => row.isDuplicate).length;
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
                      if (flagged.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ImportPreview(
                          parsed: flagged,
                          errorCount: errorCount,
                          duplicateCount: duplicateCount,
                          includedDespiteDuplicate: _includedDespiteDuplicate,
                          onToggleDuplicate: _toggleDuplicate,
                        ),
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
          "doesn't apply. A row whose phone or email matches an existing "
          'lead (or another row in this paste) is flagged as a possible '
          'duplicate and excluded by default — check it in the preview to '
          'import it anyway.',
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
  const _ImportPreview({
    required this.parsed,
    required this.errorCount,
    required this.duplicateCount,
    required this.includedDespiteDuplicate,
    required this.onToggleDuplicate,
  });

  final List<ParsedImportRow> parsed;
  final int errorCount;
  final int duplicateCount;
  final Set<int> includedDespiteDuplicate;
  final ValueChanged<int> onToggleDuplicate;

  @override
  Widget build(BuildContext context) {
    final validCount = parsed.length - errorCount;
    final importCount =
        validCount - duplicateCount + includedDespiteDuplicate.length;
    return FormSection(
      title: 'Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${parsed.length} row${parsed.length == 1 ? '' : 's'} found — '
            '$importCount ready to import'
            '${errorCount > 0 ? ', $errorCount with errors (skipped)' : ''}'
            '${duplicateCount > 0 ? ', $duplicateCount possible duplicate'
                  '${duplicateCount == 1 ? '' : 's'} (excluded by default)' : ''}'
            '.',
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

                if (row.isDuplicate) {
                  final included = includedDespiteDuplicate.contains(index);
                  return CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: included,
                    onChanged: (_) => onToggleDuplicate(index),
                    secondary: const Icon(
                      Icons.content_copy_outlined,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    title: Text(row.displayName(index)),
                    subtitle: Text(
                      '${row.duplicateReason!} — '
                      '${included ? 'will be imported' : 'skipped'}',
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  );
                }

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
