import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/financial_reports_providers.dart';
import '../../domain/entities/financial_record.dart';
import 'financial_record_editor_page.dart';

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

enum _Currency { pkr, usd }

/// Groups thousands with commas — no `intl` dependency in this app, and a
/// hand-rolled digit grouping is all whole-number currency figures need.
String _groupThousands(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String _formatMoney(double value, _Currency currency) {
  final isNegative = value < 0;
  final rounded = value.abs().round();
  final prefix = currency == _Currency.usd ? '\$' : 'Rs';
  return '${isNegative ? '-' : ''}$prefix${_groupThousands(rounded)}';
}

/// Every PKR figure on this page carries its USD equivalent in round
/// brackets right after it — one figure to read, not a separate
/// column/toggle to reconcile.
String _formatMoneyWithUsd(double valueRs, double valueUsd) =>
    '${_formatMoney(valueRs, _Currency.pkr)} (${_formatMoney(valueUsd, _Currency.usd)})';

/// Rich-text version of [_formatMoneyWithUsd]: the PKR figure inherits
/// whatever style its host `Text.rich`/`TextSpan` sets, while the bracketed
/// USD conversion is deliberately de-emphasized — lighter weight, smaller,
/// neutral grey — so it reads as a secondary conversion, not a second
/// headline number competing with the PKR one.
List<InlineSpan> _moneyValueSpans(double valueRs, double valueUsd) => [
  TextSpan(text: _formatMoney(valueRs, _Currency.pkr)),
  TextSpan(
    text: ' (${_formatMoney(valueUsd, _Currency.usd)})',
    style: const TextStyle(
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      fontSize: 12,
    ),
  ),
];

/// A short "975K" / "20.9M" form used only for direct chart labels — a bar
/// column is far too narrow for a full precise "Rs974,834", and this way
/// every value is visible on the chart itself, not just on hover. The exact
/// figure is still available via the bar's tooltip.
String _formatCompact(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final String magnitude;
  if (abs >= 1000000) {
    magnitude = '${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    magnitude = '${(abs / 1000).round()}K';
  } else {
    magnitude = abs.round().toString();
  }
  return '${isNegative ? '-' : ''}$magnitude';
}

String _formatPercent(double value) => '${value.toStringAsFixed(1)}%';

String _formatMonthYear(int month, int year) =>
    '${_kMonthAbbreviations[month - 1]} $year';

/// The Financial Reports module's root page — monthly/yearly revenue,
/// expense, and profit reporting for the whole company. Super-Admin-only
/// (see `finances.manage` in `seed.ts` and `_superAdminOnlyLabels` in
/// `main.dart`): this is real company financial data, a materially more
/// sensitive surface than the other Admin Business Management modules
/// (Clients & Projects, Payroll, Leads) which are all shared with HR/Manager.
/// New months are added/edited in-app via [FinancialRecordEditorPage] (the
/// "Add Record" button, or tapping a row in the Monthly Detail table); the
/// initial 42 months of history were a one-off import script, but ongoing
/// entry doesn't need one. Every money
/// figure is shown as PKR with its USD equivalent in brackets, always — no
/// currency toggle, since the two currencies are shown together everywhere.
class FinancialReportsPage extends ConsumerStatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  ConsumerState<FinancialReportsPage> createState() =>
      _FinancialReportsPageState();
}

class _FinancialReportsPageState extends ConsumerState<FinancialReportsPage> {
  /// `null` means "All-Time" — the default, so the page opens on the
  /// grand-total view rather than assuming the most recent year is what's
  /// wanted. Monthly detail (the two monthly charts and the detail table)
  /// stays hidden until a specific year is picked, since 40+ months of
  /// bars/rows in one view isn't "monthly detail" anymore.
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('finances.manage')) {
      return const AccessDeniedView();
    }

    final recordsAsync = ref.watch(financialRecordsListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Could not load financial reports. Please try again.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No financial records yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FinancialRecordEditorPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Record'),
                  ),
                ],
              ),
            );
          }

          final sorted = [...records]
            ..sort((a, b) {
              final byYear = a.year.compareTo(b.year);
              return byYear != 0 ? byYear : a.month.compareTo(b.month);
            });
          final years = {for (final r in sorted) r.year}.toList()
            ..sort((a, b) => b.compareTo(a));
          final selectedYear = (_selectedYear != null && years.contains(_selectedYear))
              ? _selectedYear
              : null;
          final isAllTime = selectedYear == null;
          final scopedRecords = isAllTime
              ? sorted
              : sorted.where((r) => r.year == selectedYear).toList();
          final scopeLabel = isAllTime ? 'All-Time' : '$selectedYear';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No page-body title here — the top bar already shows
                // "Financial Reports" for the active nav destination.
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 10),
                    // Tighter padding/density and no selected-checkmark icon
                    // — with up to 6 segments (All-Time + 5 years) the
                    // default Material sizing spanned the full page width.
                    SegmentedButton<int?>(
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        visualDensity: VisualDensity.compact,
                        textStyle: Theme.of(context).textTheme.labelSmall,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      showSelectedIcon: false,
                      segments: [
                        const ButtonSegment(value: null, label: Text('All-Time')),
                        for (final year in years)
                          ButtonSegment(value: year, label: Text('$year')),
                      ],
                      selected: {selectedYear},
                      onSelectionChanged: (selection) =>
                          setState(() => _selectedYear = selection.first),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FinancialRecordEditorPage(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Record'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SummaryStatsRow(records: scopedRecords, scopeLabel: scopeLabel),
                const SizedBox(height: 16),
                // Always the full history, independent of the Period
                // selector above — "from day 1" means every record, not
                // just the selected year.
                _RevenueGrowthChart(records: sorted),
                const SizedBox(height: 16),
                if (isAllTime)
                  FormSection(
                    child: Text(
                      'Select a year above to see its monthly Revenue vs '
                      'Expense, Profit/Loss, and detail table.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else ...[
                  _RevenueExpenseChart(
                    records: scopedRecords,
                    title: 'Revenue vs Expense — $scopeLabel',
                  ),
                  const SizedBox(height: 16),
                  _ProfitTrendChart(
                    records: scopedRecords,
                    title: 'Monthly Profit / Loss — $scopeLabel',
                  ),
                ],
                const SizedBox(height: 16),
                _YearlyComparisonChart(records: sorted),
                if (!isAllTime) ...[
                  const SizedBox(height: 16),
                  _MonthlyRecordsTable(records: scopedRecords),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A money-valued [MetricCard] — the value is "Rs.. (USD..)", so the exact
/// PKR figure and its USD equivalent are both always visible, no hover
/// needed.
class _MoneyMetricCard extends StatelessWidget {
  const _MoneyMetricCard({
    required this.label,
    required this.valueRs,
    required this.valueUsd,
    required this.color,
    required this.icon,
    this.secondaryValue,
  });

  final String label;
  final double valueRs;
  final double valueUsd;
  final Color color;
  final IconData icon;
  final String? secondaryValue;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      label: label,
      value: _formatMoneyWithUsd(valueRs, valueUsd),
      valueSpans: _moneyValueSpans(valueRs, valueUsd),
      secondaryValue: secondaryValue,
      color: color,
      icon: icon,
      // The default headlineSmall size suits a short number — these tiles
      // carry a full precise PKR figure plus its USD equivalent, which
      // runs much longer, so it's sized down to still read comfortably.
      valueFontSize: 16,
      labelFirst: true,
    );
  }
}

class _SummaryStatsRow extends StatelessWidget {
  const _SummaryStatsRow({required this.records, required this.scopeLabel});

  final List<FinancialRecord> records;

  /// "All-Time" or a specific year (e.g. "2026") — whichever is currently
  /// selected above.
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final first = records.first;
    final last = records.last;
    final rangeLabel = first.year == last.year && first.month == last.month
        ? _formatMonthYear(first.month, first.year)
        : '${_formatMonthYear(first.month, first.year)} – '
              '${_formatMonthYear(last.month, last.year)}';

    final totalRevenueRs = records.fold(0.0, (sum, r) => sum + r.revenueRs);
    final totalRevenueUsd = records.fold(0.0, (sum, r) => sum + r.revenueUsd);
    final totalExpenseRs = records.fold(0.0, (sum, r) => sum + r.expenseRs);
    final totalExpenseUsd = records.fold(0.0, (sum, r) => sum + r.expenseUsd);
    final totalProfitRs = totalRevenueRs - totalExpenseRs;
    final totalProfitUsd = totalRevenueUsd - totalExpenseUsd;
    final profitMargin = totalRevenueRs == 0
        ? 0.0
        : (totalProfitRs / totalRevenueRs) * 100;

    final monthCount = records.length;
    final avgRevenueRs = totalRevenueRs / monthCount;
    final avgRevenueUsd = totalRevenueUsd / monthCount;
    final avgExpenseRs = totalExpenseRs / monthCount;
    final avgExpenseUsd = totalExpenseUsd / monthCount;
    final avgProfitRs = totalProfitRs / monthCount;
    final avgProfitUsd = totalProfitUsd / monthCount;

    final byProfit = [...records]..sort((a, b) => a.profitRs.compareTo(b.profitRs));
    final worstMonth = byProfit.first;
    final bestMonth = byProfit.last;
    final profitableMonths = records.where((r) => r.profitRs >= 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Totals ($scopeLabel)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Since $rangeLabel · $monthCount month${monthCount == 1 ? '' : 's'} of data',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // No "($scopeLabel)" suffix on these labels — the "Totals
            // ($scopeLabel)" heading right above already states the scope,
            // matching how the Monthly Averages tiles below don't repeat
            // it either.
            _MoneyMetricCard(
              label: 'Total Revenue',
              valueRs: totalRevenueRs,
              valueUsd: totalRevenueUsd,
              color: AppColors.primary,
              icon: Icons.trending_up_outlined,
            ),
            _MoneyMetricCard(
              label: 'Total Expense',
              valueRs: totalExpenseRs,
              valueUsd: totalExpenseUsd,
              color: AppColors.secondary,
              icon: Icons.trending_down_outlined,
            ),
            _MoneyMetricCard(
              label: 'Total Profit',
              valueRs: totalProfitRs,
              valueUsd: totalProfitUsd,
              color: totalProfitRs >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              label: 'Profit Margin',
              value: _formatPercent(profitMargin),
              secondaryValue: '$profitableMonths of $monthCount months profitable',
              color: profitMargin >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.percent_outlined,
              // Matches the money tiles' size for visual consistency across
              // the row.
              valueFontSize: 16,
              labelFirst: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Monthly Averages & Highlights ($scopeLabel)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyMetricCard(
              label: 'Avg Monthly Revenue',
              valueRs: avgRevenueRs,
              valueUsd: avgRevenueUsd,
              color: AppColors.primary,
              icon: Icons.show_chart_outlined,
            ),
            _MoneyMetricCard(
              label: 'Avg Monthly Expense',
              valueRs: avgExpenseRs,
              valueUsd: avgExpenseUsd,
              color: AppColors.secondary,
              icon: Icons.show_chart_outlined,
            ),
            _MoneyMetricCard(
              label: 'Avg Monthly Profit',
              valueRs: avgProfitRs,
              valueUsd: avgProfitUsd,
              color: avgProfitRs >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.savings_outlined,
            ),
            _MoneyMetricCard(
              label: 'Best Month (by Profit)',
              valueRs: bestMonth.profitRs,
              valueUsd: bestMonth.profitUsd,
              secondaryValue: _formatMonthYear(bestMonth.month, bestMonth.year),
              color: AppColors.success,
              icon: Icons.emoji_events_outlined,
            ),
            _MoneyMetricCard(
              label: 'Worst Month (by Profit)',
              valueRs: worstMonth.profitRs,
              valueUsd: worstMonth.profitUsd,
              secondaryValue: _formatMonthYear(worstMonth.month, worstMonth.year),
              color: worstMonth.profitRs >= 0
                  ? AppColors.success
                  : AppColors.error,
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.entries});

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final (label, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

/// One bar within a [_GroupedBars] group: its value (drives height, in
/// PKR), its color (fixed per series identity), and its tooltip text.
typedef _BarSpec = ({double value, Color color, String tooltip});

/// A group of side-by-side bars sharing one x-axis label — 2 for the
/// monthly Revenue-vs-Expense chart, 3 for the yearly Revenue/Expense/
/// Profit comparison. Each bar's color is fixed to its series identity,
/// never cycled or reassigned.
class _GroupedBars extends StatelessWidget {
  const _GroupedBars({
    required this.label,
    required this.bars,
    required this.maxValue,
    required this.maxBarHeight,
  });

  final String label;
  final List<_BarSpec> bars;
  final double maxValue;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A direct value label per series, stacked above the bars and
          // color-matched to each — so every figure is visible without
          // hovering; the tooltip still carries the exact PKR+USD amount.
          for (final spec in bars)
            Text(
              _formatCompact(spec.value),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: spec.color,
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: maxBarHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  _bar(bars[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _bar(_BarSpec spec) {
    final fraction = (spec.value.abs() / maxValue).clamp(0.0, 1.0);
    return Tooltip(
      message: spec.tooltip,
      child: Container(
        width: 14,
        height: (maxBarHeight * fraction).clamp(4.0, maxBarHeight),
        decoration: BoxDecoration(
          color: spec.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

/// Monthly Revenue vs Expense — a grouped bar chart, one hue per series
/// (fixed: Revenue=primary, Expense=secondary), never cycled or reused
/// elsewhere as identity color.
class _RevenueExpenseChart extends StatelessWidget {
  const _RevenueExpenseChart({required this.records, required this.title});

  final List<FinancialRecord> records;
  final String title;

  static const _maxBarHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final maxValue = records
        .expand((r) => [r.revenueRs, r.expenseRs])
        .reduce((a, b) => a > b ? a : b);

    return FormSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartLegend(
            entries: [
              ('Revenue', AppColors.primary),
              ('Expense', AppColors.secondary),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            // + 40 for the month label below the bars, + 28 for the two
            // stacked value labels (Revenue/Expense) above them.
            height: _maxBarHeight + 68,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final record in records)
                    _GroupedBars(
                      // No year suffix — this chart is always scoped to one
                      // selected year, already named in its title above.
                      label: _kMonthAbbreviations[record.month - 1],
                      maxValue: maxValue == 0 ? 1 : maxValue,
                      maxBarHeight: _maxBarHeight,
                      bars: [
                        (
                          value: record.revenueRs,
                          color: AppColors.primary,
                          tooltip:
                              'Revenue: ${_formatMoneyWithUsd(record.revenueRs, record.revenueUsd)}',
                        ),
                        (
                          value: record.expenseRs,
                          color: AppColors.secondary,
                          tooltip:
                              'Expense: ${_formatMoneyWithUsd(record.expenseRs, record.expenseUsd)}',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly profit — a single series, but its polarity (profit vs loss) is
/// the whole point, so each bar is colored by sign (status-color treatment:
/// green=profit, red=loss) rather than one flat hue or a diverging gradient.
class _ProfitTrendChart extends StatelessWidget {
  const _ProfitTrendChart({required this.records, required this.title});

  final List<FinancialRecord> records;
  final String title;

  static const _maxBarHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final maxAbs = records
        .map((r) => r.profitRs.abs())
        .fold(0.0, (a, b) => a > b ? a : b);

    return FormSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartLegend(
            entries: [
              ('Profit', AppColors.success),
              ('Loss', AppColors.error),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            // + 40 for the month label below the bars, + 16 for the value
            // label above them.
            height: _maxBarHeight + 56,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final record in records)
                    _ProfitBar(
                      // No year suffix — this chart is always scoped to one
                      // selected year, already named in its title above.
                      label: _kMonthAbbreviations[record.month - 1],
                      tooltipLabel: _formatMonthYear(record.month, record.year),
                      value: record.profitRs,
                      maxAbs: maxAbs == 0 ? 1 : maxAbs,
                      maxBarHeight: _maxBarHeight,
                      formattedValue: _formatMoneyWithUsd(
                        record.profitRs,
                        record.profitUsd,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitBar extends StatelessWidget {
  const _ProfitBar({
    required this.label,
    required this.tooltipLabel,
    required this.value,
    required this.maxAbs,
    required this.maxBarHeight,
    required this.formattedValue,
  });

  final String label;
  final String tooltipLabel;
  final double value;
  final double maxAbs;
  final double maxBarHeight;
  final String formattedValue;

  @override
  Widget build(BuildContext context) {
    final fraction = (value.abs() / maxAbs).clamp(0.0, 1.0);
    final color = value >= 0 ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: '$tooltipLabel: $formattedValue',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Direct value label — visible without hovering; the tooltip
            // above still carries the exact PKR+USD amount.
            Text(
              _formatCompact(value),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: maxBarHeight,
              width: 26,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: (maxBarHeight * fraction).clamp(4.0, maxBarHeight),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yearly totals — every calendar year present, regardless of the page's
/// year selector, so the "yearly" half of the report is always visible
/// alongside the selected year's monthly detail above it. Three series
/// (Revenue/Expense/Profit) using this app's own violet/blue/teal triad —
/// Profit's own polarity (green/red) is the Monthly Profit/Loss chart's
/// job above; here it's one more named quantity being compared, so it gets
/// a fixed identity color like its two neighbors.
class _YearlyComparisonChart extends StatelessWidget {
  const _YearlyComparisonChart({required this.records});

  final List<FinancialRecord> records;

  static const _maxBarHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final byYear = <int, List<FinancialRecord>>{};
    for (final record in records) {
      byYear.putIfAbsent(record.year, () => []).add(record);
    }
    final years = byYear.keys.toList()..sort();

    final totals = {
      for (final year in years)
        year: (
          revenueRs: byYear[year]!.fold(0.0, (sum, r) => sum + r.revenueRs),
          revenueUsd: byYear[year]!.fold(0.0, (sum, r) => sum + r.revenueUsd),
          expenseRs: byYear[year]!.fold(0.0, (sum, r) => sum + r.expenseRs),
          expenseUsd: byYear[year]!.fold(0.0, (sum, r) => sum + r.expenseUsd),
          profitRs: byYear[year]!.fold(0.0, (sum, r) => sum + r.profitRs),
          profitUsd: byYear[year]!.fold(0.0, (sum, r) => sum + r.profitUsd),
        ),
    };
    final maxValue = totals.values
        .expand((t) => [t.revenueRs, t.expenseRs, t.profitRs])
        .map((v) => v.abs())
        .reduce((a, b) => a > b ? a : b);

    return FormSection(
      title: 'Revenue vs Expense vs Profit by Year',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartLegend(
            entries: [
              ('Revenue', AppColors.primary),
              ('Expense', AppColors.secondary),
              ('Profit', AppColors.accentTeal),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            // + 40 for the year label below the bars, + 42 for the three
            // stacked value labels (Revenue/Expense/Profit) above them.
            height: _maxBarHeight + 82,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final year in years)
                  _GroupedBars(
                    label: '$year',
                    maxValue: maxValue == 0 ? 1 : maxValue,
                    maxBarHeight: _maxBarHeight,
                    bars: [
                      (
                        value: totals[year]!.revenueRs,
                        color: AppColors.primary,
                        tooltip:
                            'Revenue $year: ${_formatMoneyWithUsd(totals[year]!.revenueRs, totals[year]!.revenueUsd)}',
                      ),
                      (
                        value: totals[year]!.expenseRs,
                        color: AppColors.secondary,
                        tooltip:
                            'Expense $year: ${_formatMoneyWithUsd(totals[year]!.expenseRs, totals[year]!.expenseUsd)}',
                      ),
                      (
                        value: totals[year]!.profitRs,
                        color: AppColors.accentTeal,
                        tooltip:
                            'Profit $year: ${_formatMoneyWithUsd(totals[year]!.profitRs, totals[year]!.profitUsd)}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Revenue over the entire history, oldest to newest — a single-series
/// straight-line chart, not bars, since the point is the overall growth
/// trend rather than comparing discrete categories. Scaled between the
/// data's own min/max (not from zero) so the trend line has visible slope
/// instead of being flattened near the top of a zero-based axis. Every
/// point's spacing is computed from the available width (via
/// `LayoutBuilder`) rather than a fixed pixel spacing, so the whole
/// history — every dot — always fits on screen with no horizontal
/// scrolling, however many months there are; a hover `Tooltip` on each dot
/// still carries the exact month + revenue figure, since 40+ direct labels
/// packed this tightly would be unreadable.
class _RevenueGrowthChart extends StatelessWidget {
  const _RevenueGrowthChart({required this.records});

  final List<FinancialRecord> records;

  static const _chartHeight = 160.0;
  static const _verticalPadding = 14.0;
  static const _horizontalPadding = 10.0;

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) return const SizedBox.shrink();

    final maxRevenue = records
        .map((r) => r.revenueRs)
        .reduce((a, b) => a > b ? a : b);
    final minRevenue = records
        .map((r) => r.revenueRs)
        .reduce((a, b) => a < b ? a : b);
    final range = maxRevenue - minRevenue;
    final plotHeight = _chartHeight - _verticalPadding * 2;

    double yFor(double value) {
      if (range == 0) return _verticalPadding + plotHeight / 2;
      final fraction = (value - minRevenue) / range;
      return _verticalPadding + plotHeight - (fraction * plotHeight);
    }

    return FormSection(
      title: 'Revenue Growth — All-Time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartLegend(entries: [('Revenue', AppColors.primary)]),
          const SizedBox(height: 12),
          SizedBox(
            height: _chartHeight + 26,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final plotWidth =
                    constraints.maxWidth - _horizontalPadding * 2;
                final pointSpacing = plotWidth / (records.length - 1);
                final points = [
                  for (var i = 0; i < records.length; i++)
                    Offset(
                      _horizontalPadding + i * pointSpacing,
                      yFor(records[i].revenueRs),
                    ),
                ];

                return Stack(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      height: _chartHeight,
                      child: CustomPaint(
                        painter: _LineChartPainter(
                          points: points,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    for (var i = 0; i < records.length; i++)
                      Positioned(
                        left: points[i].dx - 4,
                        top: points[i].dy - 4,
                        child: Tooltip(
                          message:
                              '${_formatMonthYear(records[i].month, records[i].year)}: '
                              '${_formatMoneyWithUsd(records[i].revenueRs, records[i].revenueUsd)}',
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    // A year label at each January (or the very first/last
                    // point, if the history doesn't start/end in January) —
                    // labeling every month across 40+ months would be
                    // unreadable. The first and last labels are anchored to
                    // stay inside the chart's own bounds rather than
                    // centered, so neither ever clips past its edge.
                    for (var i = 0; i < records.length; i++)
                      if (i == 0 || i == records.length - 1 || records[i].month == 1)
                        Positioned(
                          left: i == 0
                              ? points[i].dx
                              : (i == records.length - 1
                                    ? points[i].dx - 28
                                    : points[i].dx - 14),
                          top: _chartHeight + 6,
                          child: Text(
                            '${records[i].year}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

class _MonthlyRecordsTable extends StatelessWidget {
  const _MonthlyRecordsTable({required this.records});

  final List<FinancialRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return FormSection(
      title: 'Monthly Detail',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Rows are tap-to-edit, not multi-select — no checkbox column.
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Revenue')),
            DataColumn(label: Text('Expense')),
            DataColumn(label: Text('Profit')),
            DataColumn(label: Text('Profit %'), numeric: true),
          ],
          rows: [
            for (final record in records)
              DataRow(
                onSelectChanged: (_) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FinancialRecordEditorPage(existingRecord: record),
                  ),
                ),
                cells: [
                  DataCell(
                    Text('${_kMonthAbbreviations[record.month - 1]} ${record.year}'),
                  ),
                  DataCell(
                    Text.rich(
                      TextSpan(
                        children: _moneyValueSpans(
                          record.revenueRs,
                          record.revenueUsd,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text.rich(
                      TextSpan(
                        children: _moneyValueSpans(
                          record.expenseRs,
                          record.expenseUsd,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: record.profitRs >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        children: _moneyValueSpans(
                          record.profitRs,
                          record.profitUsd,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatPercent(record.profitPercent),
                      style: TextStyle(
                        color: record.profitPercent >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
