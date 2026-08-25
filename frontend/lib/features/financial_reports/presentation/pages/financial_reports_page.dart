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

String _formatPercent(double value) => '${value.toStringAsFixed(1)}%';

String _formatMonthYear(int month, int year) =>
    '${_kMonthAbbreviations[month - 1]} $year';

/// Month label used on the monthly charts — includes a short year (e.g.
/// "Jan\n26") so a bar is never ambiguous about which year it belongs to,
/// even though the chart itself is already scoped to one selected year.
String _formatChartMonthLabel(int month, int year) {
  final shortYear = year.toString().substring(2);
  return '${_kMonthAbbreviations[month - 1]}\n$shortYear';
}

/// The Financial Reports module's root page — monthly/yearly revenue,
/// expense, and profit reporting for the whole company. Super-Admin-only
/// (see `finances.manage` in `seed.ts` and `_superAdminOnlyLabels` in
/// `main.dart`): this is real company financial data, a materially more
/// sensitive surface than the other Admin Business Management modules
/// (Clients & Projects, Payroll, Leads) which are all shared with HR/Manager.
/// A pure reporting surface — the underlying monthly figures are entered via
/// a one-off import script, not an in-app editor, since v1 only asked for
/// "see my monthly and yearly reports in stats and graphs". Every money
/// figure is shown as PKR with its USD equivalent in brackets, always — no
/// currency toggle, since the two currencies are shown together everywhere.
class FinancialReportsPage extends ConsumerStatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  ConsumerState<FinancialReportsPage> createState() =>
      _FinancialReportsPageState();
}

class _FinancialReportsPageState extends ConsumerState<FinancialReportsPage> {
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
            return const Center(child: Text('No financial records yet.'));
          }

          final sorted = [...records]
            ..sort((a, b) {
              final byYear = a.year.compareTo(b.year);
              return byYear != 0 ? byYear : a.month.compareTo(b.month);
            });
          final years = {for (final r in sorted) r.year}.toList()
            ..sort((a, b) => b.compareTo(a));
          final selectedYear = years.contains(_selectedYear)
              ? _selectedYear!
              : years.first;
          final yearRecords = sorted.where((r) => r.year == selectedYear).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No page-body title here — the top bar already shows
                // "Financial Reports" for the active nav destination.
                _AllTimeStatsRow(records: sorted),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Year:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<int>(
                      segments: [
                        for (final year in years)
                          ButtonSegment(value: year, label: Text('$year')),
                      ],
                      selected: {selectedYear},
                      onSelectionChanged: (selection) =>
                          setState(() => _selectedYear = selection.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SummaryStatsRow(records: yearRecords, year: selectedYear),
                const SizedBox(height: 16),
                _RevenueExpenseChart(
                  records: yearRecords,
                  title: 'Revenue vs Expense — $selectedYear',
                ),
                const SizedBox(height: 16),
                _ProfitTrendChart(
                  records: yearRecords,
                  title: 'Monthly Profit / Loss — $selectedYear',
                ),
                const SizedBox(height: 16),
                _YearlyComparisonChart(records: sorted),
                const SizedBox(height: 16),
                _MonthlyRecordsTable(records: yearRecords),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The page's lead section — grand totals across every record on file,
/// independent of the year selector below it, with the exact date range
/// the figures cover spelled out so a total is never mistaken for a
/// single-year number.
class _AllTimeStatsRow extends StatelessWidget {
  const _AllTimeStatsRow({required this.records});

  /// Every record, sorted chronologically ascending.
  final List<FinancialRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final totalRevenueRs = records.fold(0.0, (sum, r) => sum + r.revenueRs);
    final totalRevenueUsd = records.fold(0.0, (sum, r) => sum + r.revenueUsd);
    final totalExpenseRs = records.fold(0.0, (sum, r) => sum + r.expenseRs);
    final totalExpenseUsd = records.fold(0.0, (sum, r) => sum + r.expenseUsd);
    final totalProfitRs = totalRevenueRs - totalExpenseRs;
    final totalProfitUsd = totalRevenueUsd - totalExpenseUsd;
    final profitMargin = totalRevenueRs == 0
        ? 0.0
        : (totalProfitRs / totalRevenueRs) * 100;

    final first = records.first;
    final last = records.last;
    final rangeLabel = first.year == last.year && first.month == last.month
        ? _formatMonthYear(first.month, first.year)
        : '${_formatMonthYear(first.month, first.year)} – '
              '${_formatMonthYear(last.month, last.year)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All-Time Totals',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Since $rangeLabel · ${records.length} months of data',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyMetricCard(
              label: 'All-Time Revenue',
              valueRs: totalRevenueRs,
              valueUsd: totalRevenueUsd,
              color: AppColors.primary,
              icon: Icons.trending_up_outlined,
            ),
            _MoneyMetricCard(
              label: 'All-Time Expense',
              valueRs: totalExpenseRs,
              valueUsd: totalExpenseUsd,
              color: AppColors.secondary,
              icon: Icons.trending_down_outlined,
            ),
            _MoneyMetricCard(
              label: 'All-Time Profit',
              valueRs: totalProfitRs,
              valueUsd: totalProfitUsd,
              color: totalProfitRs >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              label: 'All-Time Profit Margin',
              value: _formatPercent(profitMargin),
              color: profitMargin >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.percent_outlined,
              valueFontSize: 20,
              labelFirst: true,
            ),
          ],
        ),
      ],
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
  const _SummaryStatsRow({required this.records, required this.year});

  final List<FinancialRecord> records;
  final int year;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyMetricCard(
              label: 'Total Revenue ($year)',
              valueRs: totalRevenueRs,
              valueUsd: totalRevenueUsd,
              color: AppColors.primary,
              icon: Icons.trending_up_outlined,
            ),
            _MoneyMetricCard(
              label: 'Total Expense ($year)',
              valueRs: totalExpenseRs,
              valueUsd: totalExpenseUsd,
              color: AppColors.secondary,
              icon: Icons.trending_down_outlined,
            ),
            _MoneyMetricCard(
              label: 'Total Profit ($year)',
              valueRs: totalProfitRs,
              valueUsd: totalProfitUsd,
              color: totalProfitRs >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              label: 'Profit Margin ($year)',
              value: _formatPercent(profitMargin),
              secondaryValue: '$profitableMonths of $monthCount months profitable',
              color: profitMargin >= 0 ? AppColors.success : AppColors.error,
              icon: Icons.percent_outlined,
              valueFontSize: 20,
              labelFirst: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Monthly Averages & Highlights ($year)',
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
              label: 'Best Month',
              valueRs: bestMonth.profitRs,
              valueUsd: bestMonth.profitUsd,
              secondaryValue: _formatMonthYear(bestMonth.month, bestMonth.year),
              color: AppColors.success,
              icon: Icons.emoji_events_outlined,
            ),
            _MoneyMetricCard(
              label: 'Worst Month',
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
            height: _maxBarHeight + 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final record in records)
                    _GroupedBars(
                      label: _formatChartMonthLabel(record.month, record.year),
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
            height: _maxBarHeight + 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final record in records)
                    _ProfitBar(
                      label: _formatChartMonthLabel(record.month, record.year),
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
            height: _maxBarHeight + 40,
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
                cells: [
                  DataCell(
                    Text('${_kMonthAbbreviations[record.month - 1]} ${record.year}'),
                  ),
                  DataCell(
                    Text(_formatMoneyWithUsd(record.revenueRs, record.revenueUsd)),
                  ),
                  DataCell(
                    Text(_formatMoneyWithUsd(record.expenseRs, record.expenseUsd)),
                  ),
                  DataCell(
                    Text(
                      _formatMoneyWithUsd(record.profitRs, record.profitUsd),
                      style: TextStyle(
                        color: record.profitRs >= 0
                            ? AppColors.success
                            : AppColors.error,
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
