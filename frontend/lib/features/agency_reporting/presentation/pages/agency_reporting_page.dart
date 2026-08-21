import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/agency_reporting_providers.dart';
import '../../domain/entities/agency_report.dart';

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

/// The immediately-preceding period of the same length — e.g. for "Aug 1-21"
/// that's "Jul 11-31" (21 days), not necessarily the calendar-previous month.
DateTimeRange _previousPeriod(DateTimeRange range) {
  final days = range.end.difference(range.start).inDays + 1;
  final prevEnd = range.start.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(Duration(days: days - 1));
  return DateTimeRange(start: prevStart, end: prevEnd);
}

/// Company-wide revenue/profit/client dashboard — Super-Admin-only (gated by
/// nav visibility in main.dart, and by `reports.view` on the backend route).
class AgencyReportingPage extends ConsumerStatefulWidget {
  const AgencyReportingPage({super.key});

  @override
  ConsumerState<AgencyReportingPage> createState() =>
      _AgencyReportingPageState();
}

class _AgencyReportingPageState extends ConsumerState<AgencyReportingPage> {
  late String _presetLabel;
  late DateTimeRange _range;
  bool _compare = false;

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

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      agencyReportProvider((from: _isoDate(_range.start), to: _isoDate(_range.end))),
    );
    final previousRange = _compare ? _previousPeriod(_range) : null;
    final previousReportAsync = previousRange == null
        ? null
        : ref.watch(
            agencyReportProvider((
              from: _isoDate(previousRange.start),
              to: _isoDate(previousRange.end),
            )),
          );

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
                  compare: _compare,
                  onSelectPreset: _selectPreset,
                  onPickCustom: _pickCustomRange,
                  onCompareChanged: (value) => setState(() => _compare = value),
                  onRefresh: () {
                    ref.invalidate(
                      agencyReportProvider((
                        from: _isoDate(_range.start),
                        to: _isoDate(_range.end),
                      )),
                    );
                    if (previousRange != null) {
                      ref.invalidate(
                        agencyReportProvider((
                          from: _isoDate(previousRange.start),
                          to: _isoDate(previousRange.end),
                        )),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                reportAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Text(
                    'Could not load the report. Please try again.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (report) => _ReportBody(
                    report: report,
                    previous: previousReportAsync?.valueOrNull,
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
    required this.compare,
    required this.onSelectPreset,
    required this.onPickCustom,
    required this.onCompareChanged,
    required this.onRefresh,
  });

  final DateTime now;
  final String presetLabel;
  final DateTimeRange range;
  final bool compare;
  final void Function(String label, DateTimeRange range) onSelectPreset;
  final VoidCallback onPickCustom;
  final ValueChanged<bool> onCompareChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('This Month'),
              selected: presetLabel == 'This Month',
              onSelected: (_) =>
                  onSelectPreset('This Month', _thisMonthRange(now)),
            ),
            ChoiceChip(
              label: const Text('Last Month'),
              selected: presetLabel == 'Last Month',
              onSelected: (_) =>
                  onSelectPreset('Last Month', _lastMonthRange(now)),
            ),
            ChoiceChip(
              label: const Text('This Year'),
              selected: presetLabel == 'This Year',
              onSelected: (_) =>
                  onSelectPreset('This Year', _thisYearRange(now)),
            ),
            ChoiceChip(
              label: const Text('Last Year'),
              selected: presetLabel == 'Last Year',
              onSelected: (_) =>
                  onSelectPreset('Last Year', _lastYearRange(now)),
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(value: compare, onChanged: onCompareChanged),
            const SizedBox(width: 4),
            const Text('Compare to previous period'),
          ],
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.previous});

  final AgencyReport report;
  final AgencyReport? previous;

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
              label: 'Total Revenue',
              value: 'PKR ${formatWholeAmount(report.totalRevenue)}',
              secondaryValue: formatUsdApprox(report.totalRevenue),
              color: AppColors.primary,
              icon: Icons.payments_outlined,
              delta: _percentDelta(report.totalRevenue, previous?.totalRevenue),
            ),
            _StatTile(
              label: 'Total Cost',
              value: 'PKR ${formatWholeAmount(report.totalCost)}',
              secondaryValue: formatUsdApprox(report.totalCost),
              color: AppColors.warning,
              icon: Icons.money_off_outlined,
              delta: _percentDelta(report.totalCost, previous?.totalCost),
            ),
            _StatTile(
              label: 'Net Profit',
              value: 'PKR ${formatWholeAmount(report.netProfit)}',
              secondaryValue: formatUsdApprox(report.netProfit),
              color: AppColors.success,
              icon: Icons.trending_up,
              delta: _percentDelta(report.netProfit, previous?.netProfit),
            ),
            _StatTile(
              label: 'Monthly Recurring Revenue',
              value:
                  'PKR ${formatWholeAmount(report.activeMonthlyRecurringRevenue)}',
              secondaryValue: formatUsdApprox(
                report.activeMonthlyRecurringRevenue,
              ),
              color: AppColors.secondary,
              icon: Icons.autorenew,
            ),
            _StatTile(
              label: 'One-time Revenue',
              value: 'PKR ${formatWholeAmount(report.oneTimeRevenue)}',
              secondaryValue: formatUsdApprox(report.oneTimeRevenue),
              color: AppColors.accentTeal,
              icon: Icons.bolt_outlined,
              delta: _percentDelta(report.oneTimeRevenue, previous?.oneTimeRevenue),
            ),
            _StatTile(
              label: 'Active Clients',
              value: '${report.activeClientsCount}',
              color: AppColors.primary,
              icon: Icons.groups_outlined,
            ),
            _StatTile(
              label: 'New Clients',
              value: '${report.newClientsCount}',
              color: AppColors.success,
              icon: Icons.person_add_alt_outlined,
              delta: _percentDelta(
                report.newClientsCount.toDouble(),
                previous?.newClientsCount.toDouble(),
              ),
            ),
            _StatTile(
              label: 'Lost Clients',
              value: '${report.lostClientsCount}',
              color: AppColors.error,
              icon: Icons.person_remove_alt_1_outlined,
              delta: _percentDelta(
                report.lostClientsCount.toDouble(),
                previous?.lostClientsCount.toDouble(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FormSection(
          title: 'Projects by Status',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Active: ${report.projectsByStatus.active}')),
              Chip(label: Text('On Hold: ${report.projectsByStatus.onHold}')),
              Chip(
                label: Text('Completed: ${report.projectsByStatus.completed}'),
              ),
              Chip(
                label: Text('Cancelled: ${report.projectsByStatus.cancelled}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FormSection(
          title: 'Top Clients by Profit',
          child: report.topClientsByProfit.isEmpty
              ? Text(
                  'No project profit in this range yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < report.topClientsByProfit.length; i++) ...[
                      _ClientProfitRow(
                        rank: i + 1,
                        entry: report.topClientsByProfit[i],
                      ),
                      if (i < report.topClientsByProfit.length - 1)
                        const Divider(height: 16, color: AppColors.borderSubtle),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  double? _percentDelta(double current, double? previousValue) {
    if (previousValue == null || previousValue == 0) return null;
    return ((current - previousValue) / previousValue) * 100;
  }
}

class _ClientProfitRow extends StatelessWidget {
  const _ClientProfitRow({required this.rank, required this.entry});

  final int rank;
  final AgencyReportClientProfit entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$rank.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Text(entry.clientName, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          'PKR ${formatWholeAmount(entry.profit)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
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
    this.delta,
  });

  final String label;
  final String value;
  final String? secondaryValue;
  final Color color;
  final IconData icon;

  /// Percentage change vs. the comparison period, or null if not comparing
  /// (or the previous period had no baseline to compare against).
  final double? delta;

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
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              if (delta != null) _DeltaBadge(delta: delta!),
            ],
          ),
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

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: color,
        ),
        Text(
          '${delta.abs().toStringAsFixed(0)}%',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
