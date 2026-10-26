import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/leave_calendar_entry.dart';
import '../utils/leave_format_utils.dart';
import '../../../../shared/widgets/app_dialog.dart';

const _monthNames = [
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
const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _maxEntriesPerCell = 2;

/// A custom-built month grid (no calendar package) showing who's on leave
/// each day, scoped to the viewer's department or the whole company — lets
/// anyone spot scheduling conflicts before applying. The "My Team" scope is
/// only meaningful for department heads, so its toggle is hidden for anyone
/// else (including Super Admin, who has no department at all).
class LeaveCalendarView extends ConsumerStatefulWidget {
  const LeaveCalendarView({super.key, this.initialScope = 'team'});

  /// Which scope a department head starts on ('team' or 'company'). Everyone
  /// else is always on 'company', so this only matters for heads — the
  /// dashboard passes 'company' so it shows the whole company's leave.
  final String initialScope;

  @override
  ConsumerState<LeaveCalendarView> createState() => _LeaveCalendarViewState();
}

class _LeaveCalendarViewState extends ConsumerState<LeaveCalendarView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _scope = widget.initialScope;

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    // AsyncError.valueOrNull can still return a stale previous value (e.g.
    // right after "return to admin", while the Super Admin's 404 for
    // getMe() is settling) — pattern-match on AsyncData so an errored
    // lookup (no Employee profile) is never mistaken for someone else's
    // cached profile.
    final myProfileAsync = ref.watch(myProfileProvider);
    final myEmployeeId = switch (myProfileAsync) {
      AsyncData(:final value) => value.id,
      _ => null,
    };
    final departmentsAsync = ref.watch(departmentsProvider);
    final departments = switch (departmentsAsync) {
      AsyncData(:final value) => value,
      _ => const <Department>[],
    };
    final isDepartmentHead =
        myEmployeeId != null &&
        departments.any(
          (department) => department.headEmployeeId == myEmployeeId,
        );
    final effectiveScope = isDepartmentHead ? _scope : 'company';

    final entriesAsync = ref.watch(
      leaveCalendarProvider(
        LeaveCalendarQuery(
          scope: effectiveScope,
          month: _month.month,
          year: _month.year,
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous month',
                    ),
                    Text(
                      '${_monthNames[_month.month - 1]} ${_month.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next month',
                    ),
                  ],
                ),
                if (isDepartmentHead)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'team', label: Text('My Team')),
                      ButtonSegment(value: 'company', label: Text('Company')),
                    ],
                    selected: {_scope},
                    onSelectionChanged: (selection) =>
                        setState(() => _scope = selection.first),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('Could not load the leave calendar.'),
              data: (entries) => _MonthGrid(month: _month, entries: entries),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.entries});

  final DateTime month;
  final List<LeaveCalendarEntry> entries;

  Map<int, List<LeaveCalendarEntry>> _groupByDay() {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final map = <int, List<LeaveCalendarEntry>>{};
    for (final entry in entries) {
      final start = DateTime.parse(entry.startDate);
      final end = DateTime.parse(entry.endDate);
      for (var day = 1; day <= daysInMonth; day++) {
        final current = DateTime(month.year, month.month, day);
        if (!current.isBefore(start) && !current.isAfter(end)) {
          map.putIfAbsent(day, () => []).add(entry);
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final byDay = _groupByDay();
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 7; col++)
                _dayCellFor(
                  month: month,
                  row: row,
                  col: col,
                  leadingBlanks: leadingBlanks,
                  daysInMonth: daysInMonth,
                  byDay: byDay,
                ),
            ],
          ),
      ],
    );
  }
}

Widget _dayCellFor({
  required DateTime month,
  required int row,
  required int col,
  required int leadingBlanks,
  required int daysInMonth,
  required Map<int, List<LeaveCalendarEntry>> byDay,
}) {
  final day = row * 7 + col - leadingBlanks + 1;
  final validDay = (day >= 1 && day <= daysInMonth) ? day : null;
  return Expanded(
    child: _DayCell(
      day: validDay,
      month: month,
      entries: validDay == null
          ? const <LeaveCalendarEntry>[]
          : (byDay[validDay] ?? const <LeaveCalendarEntry>[]),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.entries,
  });

  final int? day;
  final DateTime month;
  final List<LeaveCalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox(height: 76);

    final shown = entries.take(_maxEntriesPerCell).toList();
    final overflow = entries.length - shown.length;

    return Container(
      height: 76,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        key: Key('leave-day-$day'),
        borderRadius: BorderRadius.circular(6),
        onTap: entries.isEmpty
            ? null
            : () => showAppDialog<void>(
                context: context,
                builder: (_) => _DayLeavesDialog(
                  date: DateTime(month.year, month.month, day!),
                  entries: entries,
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$day', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in shown) _EntryChip(entry: entry),
                      if (overflow > 0)
                        Text(
                          '+$overflow more',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everyone on leave on one day — the cell itself only has room for a few
/// chips, so this is where "+N more" is actually readable.
class _DayLeavesDialog extends StatelessWidget {
  const _DayLeavesDialog({required this.date, required this.entries});

  final DateTime date;
  final List<LeaveCalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'On leave · ${_monthNames[date.month - 1]} ${date.day}, ${date.year}',
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color:
                              parseLeaveColor(entry.colorHex) ??
                              AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${entry.employeeName} — ${entry.leaveTypeName}'
                          '${entry.isPending ? ' (awaiting approval)' : ''}',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({required this.entry});

  final LeaveCalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = parseLeaveColor(entry.colorHex) ?? AppColors.primary;
    final firstName = entry.employeeName.split(' ').first;
    return Tooltip(
      message: '${entry.employeeName} — ${entry.leaveTypeName}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: (entry.isPending ? color.withValues(alpha: 0.5) : color)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          firstName,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
