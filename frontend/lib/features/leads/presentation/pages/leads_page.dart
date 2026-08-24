import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/leads_providers.dart';
import '../../domain/entities/lead.dart';
import 'lead_editor_page.dart';

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

/// Maps the free-text `Lead.country` values actually present in the
/// imported sales-log data (including typos and cities entered in place of
/// a country, e.g. "Dubai", "Rawalpindi") to a short display code. Lookup
/// is case-insensitive; anything not covered here falls back to the
/// original text rather than guessing at a code.
const _kCountryShortCodes = {
  'pakistan': 'PK',
  'pakisan': 'PK',
  'karachi': 'PK',
  'rawalpindi': 'PK',
  'uae': 'UAE',
  'dubai': 'UAE',
  'united arab emirates': 'UAE',
  'uk': 'UK',
  'united kingdom': 'UK',
  'usa': 'USA',
  'us': 'USA',
  'united states': 'USA',
  'saudi arabia': 'KSA',
  'saudia': 'KSA',
  'sa': 'KSA',
  'riyadh': 'KSA',
  'australia': 'AU',
  'india': 'IN',
  'germany': 'DE',
  'italy': 'IT',
  'oman': 'OM',
  'china': 'CN',
  'canada': 'CA',
  'ca': 'CA',
  'singapore': 'SG',
  'uganda': 'UG',
  'kuwait': 'KW',
  'morocco': 'MA',
  'netherlands': 'NL',
  'netherland': 'NL',
  'qatar': 'QA',
  'south africa': 'ZA',
  'laos': 'LA',
  'malaysia': 'MY',
  'bangladesh': 'BD',
  'bahrain': 'BH',
  'turkiye/turkey': 'TR',
  'turkey': 'TR',
  'turkiye': 'TR',
  'switzerland': 'CH',
  'spain': 'ES',
  'france': 'FR',
  'slovenia': 'SI',
  'afghanistan': 'AF',
  'georgia': 'GE',
  'portugal': 'PT',
  'belgium': 'BE',
  'vietnam': 'VN',
  'botswana': 'BW',
  'philippines': 'PH',
  'nigeria': 'NG',
  'japan': 'JP',
  'ethopia': 'ET',
  'ethiopia': 'ET',
  'latvia': 'LV',
};

/// Short display code for a country value, falling back to the original
/// text unchanged when it isn't in [_kCountryShortCodes] — never invents a
/// code for a value it doesn't recognize.
String? _formatCountryShort(String? country) {
  if (country == null) return null;
  final trimmed = country.trim();
  if (trimmed.isEmpty) return null;
  return _kCountryShortCodes[trimmed.toLowerCase()] ?? trimmed;
}

/// The Leads module's root page — a simple CRM-style list of prospective
/// clients gated by `leads.manage` (shared by Super Admin and HR/Manager,
/// same as Clients & Projects and Payroll). Rendered as a spreadsheet-style
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Leads',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
            const SizedBox(height: 16),
            const _LeadsStatsRow(),
            const SizedBox(height: 16),
            const _MonthlyLeadsChart(),
            const SizedBox(height: 16),
            const _LeadsBreakdownRow(),
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
      ],
    );
  }
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

        final months = counts.keys.toList()..sort();
        final maxCount = counts.values.reduce((a, b) => a > b ? a : b);

        return FormSection(
          title: 'Leads by Month',
          child: SizedBox(
            height: 160,
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
        Map<String, int> topCounts(String? Function(Lead) selector) {
          final counts = <String, int>{};
          for (final lead in leads) {
            final value = selector(lead)?.trim();
            if (value == null || value.isEmpty) continue;
            counts[value] = (counts[value] ?? 0) + 1;
          }
          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return Map.fromEntries(sorted.take(5));
        }

        final panels = [
          _TopBreakdownPanel(
            title: 'Top Countries',
            icon: Icons.public_outlined,
            color: AppColors.primary,
            counts: topCounts((l) => _formatCountryShort(l.country)),
          ),
          _TopBreakdownPanel(
            title: 'Top Services',
            icon: Icons.design_services_outlined,
            color: AppColors.secondary,
            counts: topCounts((l) => l.serviceInterested),
          ),
          _TopBreakdownPanel(
            title: 'Top Lead Sources',
            icon: Icons.campaign_outlined,
            color: AppColors.accentTeal,
            counts: topCounts((l) => l.leadSource),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (final panel in panels) ...[
                    panel,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < panels.length; i++) ...[
                  Expanded(child: panels[i]),
                  if (i < panels.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TopBreakdownPanel extends StatelessWidget {
  const _TopBreakdownPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.counts,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.values.isEmpty ? 1 : counts.values.first;
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (counts.isEmpty)
            Text(
              'No data yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final entry in counts.entries) ...[
              _BreakdownBarRow(
                label: entry.key,
                count: entry.value,
                fraction: entry.value / maxCount,
                color: color,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _BreakdownBarRow extends StatelessWidget {
  const _BreakdownBarRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.04, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// A spreadsheet-style grid: a fixed header row of column labels, then a
/// virtualized [ListView.builder] of aligned, fixed-column rows with
/// vertical cell dividers and alternating row shading — the "Excel" look
/// requested for this list, which a card-per-lead layout couldn't give at
/// 2,000+ rows without either scrolling forever or losing at-a-glance
/// scannability across columns.
class _LeadsTable extends StatelessWidget {
  const _LeadsTable({required this.leads});

  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
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
                itemCount: leads.length,
                itemBuilder: (context, index) => _LeadsTableRow(
                  lead: leads[index],
                  isEven: index.isEven,
                ),
              ),
            ),
          ],
        ),
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
      _formatCountryShort(lead.country) ?? '—',
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
