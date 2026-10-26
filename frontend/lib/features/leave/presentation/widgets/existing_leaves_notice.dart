import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/leave_calendar_entry.dart';

/// Warns, while someone is picking dates to apply for leave, that the
/// employee already has leave (approved or still waiting on approval) that
/// overlaps them — so a duplicate is noticed before it is submitted. Reads the
/// same company calendar the month grid uses, one query per month the picked
/// range touches, and renders nothing until a start date is chosen or when
/// there is no overlap.
class ExistingLeavesNotice extends ConsumerWidget {
  const ExistingLeavesNotice({
    super.key,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  final String? employeeId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = employeeId;
    final start = startDate;
    if (id == null || start == null) return const SizedBox.shrink();
    var end = endDate ?? start;
    if (end.isBefore(start)) end = start;

    final overlapping = <LeaveCalendarEntry>[];
    var cursor = DateTime(start.year, start.month);
    while (!cursor.isAfter(DateTime(end.year, end.month))) {
      final entries = ref
          .watch(
            leaveCalendarProvider(
              LeaveCalendarQuery(
                scope: 'company',
                month: cursor.month,
                year: cursor.year,
              ),
            ),
          )
          .valueOrNull;
      for (final entry in entries ?? const <LeaveCalendarEntry>[]) {
        if (entry.employeeId != id || overlapping.contains(entry)) continue;
        final entryStart = DateTime.parse(entry.startDate);
        final entryEnd = DateTime.parse(entry.endDate);
        if (!entryStart.isAfter(end) && !entryEnd.isBefore(start)) {
          overlapping.add(entry);
        }
      }
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    if (overlapping.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('existing-leaves-notice'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Already has leave in this period',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (final entry in overlapping)
            Text(
              '${entry.leaveTypeName}: ${_range(entry)}'
              '${entry.isPending ? ' (awaiting approval)' : ' (approved)'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

String _range(LeaveCalendarEntry entry) {
  final start = formatDisplayDateOnly(_utcDay(entry.startDate));
  if (entry.startDate == entry.endDate) return start;
  return '$start – ${formatDisplayDateOnly(_utcDay(entry.endDate))}';
}

DateTime _utcDay(String iso) => DateTime.parse('${iso}T00:00:00Z');
