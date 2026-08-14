import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/audit_log_entry.dart';

const _pageSize = 10;
const _searchDebounce = Duration(milliseconds: 400);

/// Combined, searchable, paginated change history across every employee —
/// visible only to viewers with `audit.viewAll` (Super Admin, by default seed
/// config).
class CompanyAuditLogSection extends ConsumerStatefulWidget {
  const CompanyAuditLogSection({super.key});

  @override
  ConsumerState<CompanyAuditLogSection> createState() =>
      _CompanyAuditLogSectionState();
}

class _CompanyAuditLogSectionState extends ConsumerState<CompanyAuditLogSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _search;
  int _page = 1;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final trimmed = value.trim();
      setState(() {
        _search = trimmed.isEmpty ? null : trimmed;
        _page = 1;
      });
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _search = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = CompanyAuditLogQuery(
      page: _page,
      limit: _pageSize,
      search: _search,
    );
    final auditLogAsync = ref.watch(companyAuditLogProvider(query));

    return FormSection(
      title: 'Company-wide Changes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search changes',
              hintText: 'Employee, field, actor…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          auditLogAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('Could not load the combined change log.'),
            data: (result) {
              if (result.items.isEmpty) {
                return Text(
                  _search == null
                      ? 'No changes recorded yet.'
                      : 'No changes match your search.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < result.items.length; i++) ...[
                    _CompanyAuditLogRow(entry: result.items[i]),
                    if (i < result.items.length - 1)
                      const Divider(height: 20, color: AppColors.borderSubtle),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 10),
                  _PaginationFooter(
                    page: result.page,
                    totalPages: result.totalPages,
                    total: result.total,
                    onPrevious: result.page > 1
                        ? () => setState(() => _page--)
                        : null,
                    onNext: result.page < result.totalPages
                        ? () => setState(() => _page++)
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.totalPages,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Page $page of $totalPages · $total total',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          tooltip: 'Previous page',
          onPressed: onPrevious,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          tooltip: 'Next page',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _CompanyAuditLogRow extends StatelessWidget {
  const _CompanyAuditLogRow({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final emphasisStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: entry.actorName, style: emphasisStyle),
                const TextSpan(text: ' changed '),
                TextSpan(
                  text: entry.employeeName ?? 'an employee',
                  style: emphasisStyle,
                ),
                TextSpan(
                  text: "'s ${entry.fieldLabel}: ${entry.describeChange}",
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatDisplayDateTime(entry.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
