import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/country_short_code.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../../shared/widgets/top_breakdown_panel.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
import 'lead_editor_page.dart';
import 'lead_import_page.dart';

const _kMonthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// (label, flex) for each spreadsheet-style column — shared between the
/// header and every data row so widths always line up. Phone/Email get
/// extra room since they were cramped and unreadable at flex 2/3; Country
/// gives that room back since it now renders as a short code (PK, UAE, ...)
/// rather than a full name.
const _kLeadColumns = [
  ('Date', 2),
  ('Full Name', 3),
  ('Company', 2),
  ('Phone', 3),
  ('Email', 4),
  ('Country', 2),
  ('Service Interested', 3),
  ('Lead Source', 2),
  ('Remarks', 4),
];

/// The Leads module's root page — a simple CRM-style list of prospective
/// clients gated by `leads.manage`, Super-Admin-exclusive since 2026-08-28
/// (previously shared with HR/Manager, like Clients & Projects and Payroll
/// still are). Rendered as a spreadsheet-style
/// grid (fixed columns, header row, zebra striping) rather than a card list,
/// since the underlying data is a flat, column-shaped import from a sales
/// log — a table reads closer to the source than a list of cards would.
class LeadsPage extends ConsumerWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('leads.manage')) {
      return const AccessDeniedView();
    }

    final leadsAsync = ref.watch(leadsListProvider);

    // The insights section (stats/chart/breakdowns) added enough content
    // that it can no longer share a fixed-height `Expanded` region with the
    // table on shorter windows — the whole page scrolls instead, with the
    // table given its own generous fixed-height, internally-virtualized
    // scroll region (still fine at 2,000+ rows, since ListView.builder
    // doesn't care whether its own height came from Expanded or a SizedBox).
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LeadImportPage()),
                    ),
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Import Leads'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LeadEditorPage()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Lead'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _LeadsStatsRow(),
            const SizedBox(height: 16),
            const _LeadsBreakdownRow(),
            const SizedBox(height: 16),
            const _MonthlyLeadsChart(),
            const SizedBox(height: 16),
            leadsAsync.when(
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Could not load leads. Please try again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              data: (leads) {
                if (leads.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: Text('No leads yet.')),
                  );
                }
                return SizedBox(height: 560, child: _LeadsTable(leads: leads));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadsStatsRow extends ConsumerWidget {
  const _LeadsStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsListProvider);

    if (leadsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (leadsAsync.hasError) {
      return Text(
        'Could not load the summary.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    final leads = leadsAsync.value ?? const [];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    bool onOrAfter(Lead lead, DateTime threshold) {
      final date = DateTime.tryParse(lead.leadDate);
      return date != null && !date.isBefore(threshold);
    }

    final newThisWeek = leads.where((l) => onOrAfter(l, weekAgo)).length;
    final newThisMonth = leads.where((l) => onOrAfter(l, monthStart)).length;

    // Same selectors (and the same flag-formatted country grouping) as the
    // "Top Countries/Lead Sources" panels below, so these totals never
    // disagree with what those panels are drawing from — just uncapped,
    // since the panels themselves only show their top 5.
    final totalCountries = _countDistinct(
      leads,
      (l) => formatCountryFlag(l.country),
    );
    final totalLeadSources = _countDistinct(leads, (l) => l.leadSource);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        MetricCard(
          label: 'Total Leads',
          value: '${leads.length}',
          color: AppColors.primary,
          icon: Icons.person_search_outlined,
        ),
        MetricCard(
          label: 'New This Week',
          value: '$newThisWeek',
          color: AppColors.secondary,
          icon: Icons.bolt_outlined,
        ),
        MetricCard(
          label: 'New This Month',
          value: '$newThisMonth',
          color: AppColors.accentTeal,
          icon: Icons.calendar_month_outlined,
        ),
        MetricCard(
          label: 'Total Countries',
          value: '$totalCountries',
          color: AppColors.primary,
          icon: Icons.public_outlined,
        ),
        MetricCard(
          label: 'Total Lead Sources',
          value: '$totalLeadSources',
          color: AppColors.accentTeal,
          icon: Icons.campaign_outlined,
        ),
      ],
    );
  }
}

/// Count of distinct non-empty values `selector` returns across `items` —
/// same trim/skip-empty normalization as [computeTopCounts], just without
/// its top-N truncation.
int _countDistinct<T>(List<T> items, String? Function(T) selector) {
  final values = <String>{};
  for (final item in items) {
    final value = selector(item)?.trim();
    if (value != null && value.isNotEmpty) values.add(value);
  }
  return values.length;
}

/// A single-series bar chart of lead volume per calendar month — a plain
/// hand-rolled bar chart (this app has no charting package dependency and
/// the codebase's own convention is to avoid adding one for a single simple
/// chart), one hue throughout since it's one series over time, not a
/// category comparison.
class _MonthlyLeadsChart extends ConsumerWidget {
  const _MonthlyLeadsChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsListProvider);
    return leadsAsync.maybeWhen(
      data: (leads) {
        final counts = <String, int>{};
        for (final lead in leads) {
          final date = DateTime.tryParse(lead.leadDate);
          if (date == null) continue;
          final key =
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        if (counts.isEmpty) return const SizedBox.shrink();

        // Newest month first (leftmost), oldest trailing off to the right —
        // so the most recent activity is visible without scrolling.
        final months = counts.keys.toList()..sort((a, b) => b.compareTo(a));
        final maxCount = counts.values.reduce((a, b) => a > b ? a : b);

        return FormSection(
          title: 'Leads by Month',
          child: SizedBox(
            height: 178,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in months)
                    _MonthBar(
                      label: _formatMonthLabel(month),
                      count: counts[month]!,
                      fraction: counts[month]! / maxCount,
                    ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

String _formatMonthLabel(String monthKey) {
  final parts = monthKey.split('-');
  final shortYear = parts[0].substring(2);
  final monthIndex = int.parse(parts[1]) - 1;
  return '${_kMonthAbbreviations[monthIndex]}\n$shortYear';
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String label;
  final int count;
  final double fraction;

  static const _maxBarHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: '$label: $count lead${count == 1 ? '' : 's'}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A direct count label above each bar — visible without
            // hovering; the tooltip above still carries the full sentence.
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: _maxBarHeight,
              width: 26,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: (_maxBarHeight * fraction).clamp(4.0, _maxBarHeight),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 38,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three "top N" categorical breakdowns — countries, services, and lead
/// sources — each its own panel with one representative hue (magnitude
/// within a panel, not identity across panels, so a single hue per panel is
/// correct rather than a categorical palette).
class _LeadsBreakdownRow extends ConsumerWidget {
  const _LeadsBreakdownRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsListProvider);
    return leadsAsync.maybeWhen(
      data: (leads) {
        final panels = [
          TopBreakdownPanel(
            title: 'Top Countries',
            icon: Icons.public_outlined,
            color: AppColors.primary,
            counts: computeTopCounts(leads, (l) => formatCountryFlag(l.country)),
          ),
          TopBreakdownPanel(
            title: 'Top Services',
            icon: Icons.design_services_outlined,
            color: AppColors.secondary,
            counts: computeTopCounts(leads, (l) => l.serviceInterested),
          ),
          TopBreakdownPanel(
            title: 'Top Lead Sources',
            icon: Icons.campaign_outlined,
            color: AppColors.accentTeal,
            counts: computeTopCounts(leads, (l) => l.leadSource),
          ),
        ];

        return TopBreakdownRow(panels: panels);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// A spreadsheet-style grid: a fixed header row of column labels, then a
/// virtualized [ListView.builder] of aligned, fixed-column rows with
/// vertical cell dividers and alternating row shading — the "Excel" look
/// requested for this list, which a card-per-lead layout couldn't give at
/// 2,000+ rows without either scrolling forever or losing at-a-glance
/// scannability across columns.
/// Paginated at 50 rows/page — `leads` already arrives newest-first (the
/// backend's default `GET /leads` order), so page 1 is always the most
/// recent 50 leads, not an arbitrary slice.
class _LeadsTable extends StatefulWidget {
  const _LeadsTable({required this.leads});

  final List<Lead> leads;

  static const _pageSize = 50;

  @override
  State<_LeadsTable> createState() => _LeadsTableState();
}

class _LeadsTableState extends State<_LeadsTable> {
  int _page = 0;

  @override
  void didUpdateWidget(_LeadsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A changed lead list (e.g. a new lead was just created) invalidates
    // whatever page index was in view — back to the newest page.
    if (oldWidget.leads.length != widget.leads.length) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = (widget.leads.length / _LeadsTable._pageSize).ceil();
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _LeadsTable._pageSize;
    final end = (start + _LeadsTable._pageSize).clamp(0, widget.leads.length);
    final pageLeads = widget.leads.sublist(start, end);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            const _LeadsTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: pageLeads.length,
                itemBuilder: (context, index) => _LeadsTableRow(
                  lead: pageLeads[index],
                  isEven: index.isEven,
                ),
              ),
            ),
            _LeadsTablePagination(
              start: start + 1,
              end: end,
              total: widget.leads.length,
              page: page,
              pageCount: pageCount,
              onPrevious: page > 0 ? () => setState(() => _page = page - 1) : null,
              onNext: page < pageCount - 1
                  ? () => setState(() => _page = page + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadsTablePagination extends StatelessWidget {
  const _LeadsTablePagination({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start–$end of $total',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: 'Previous page',
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Page ${page + 1} of $pageCount',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: 'Next page',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadsTableHeader extends StatelessWidget {
  const _LeadsTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (final (label, flex) in _kLeadColumns)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadsTableRow extends StatelessWidget {
  const _LeadsTableRow({required this.lead, required this.isEven});

  final Lead lead;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final cellStyle = Theme.of(context).textTheme.bodySmall;
    final cells = [
      lead.leadDate,
      lead.fullName,
      lead.companyName ?? '—',
      lead.phone ?? '—',
      lead.email ?? '—',
      formatCountryFlag(lead.country) ?? '—',
      lead.serviceInterested ?? '—',
      lead.leadSource ?? '—',
      lead.remarks ?? '—',
    ];

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LeadEditorPage(existingLead: lead)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isEven ? AppColors.surface : AppColors.canvasBackground,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            for (var i = 0; i < _kLeadColumns.length; i++)
              Expanded(
                flex: _kLeadColumns[i].$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: i < _kLeadColumns.length - 1
                      ? const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.borderSubtle),
                          ),
                        )
                      : null,
                  child: Tooltip(
                    message: cells[i],
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      cells[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: i == 1
                          ? cellStyle?.copyWith(fontWeight: FontWeight.w600)
                          : cellStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
