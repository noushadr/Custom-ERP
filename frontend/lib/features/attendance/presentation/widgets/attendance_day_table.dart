import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/attendance.dart';

(String, Color?) _statusLabel(String status) => switch (status) {
  AttendanceStatus.present => ('Present', AppColors.success),
  AttendanceStatus.late => ('Late', AppColors.warning),
  AttendanceStatus.incomplete => ('No check-out', AppColors.warning),
  AttendanceStatus.missingCheckin => ('Missing check-in', AppColors.warning),
  AttendanceStatus.hoursCut => ('Hours cut', AppColors.error),
  AttendanceStatus.wfh => ('Work from home', AppColors.primary),
  AttendanceStatus.absent => ('Absent', AppColors.error),
  AttendanceStatus.leave => ('Leave', AppColors.secondary),
  AttendanceStatus.holiday => ('Holiday', AppColors.accentTeal),
  AttendanceStatus.weekend => ('Weekend', AppColors.textSecondary),
  _ => ('', null),
};

/// "5m", "1hr 40m" — a length of time in words rather than HH:mm.
String _duration(int minutes) =>
    formatAttendanceMinutes(minutes, blankZero: false);

/// The clock-in time, with how late it was beside it in a different colour.
Widget _clockIn(AttendanceDay day) {
  if (day.clockIn == null) return const Text('');
  if (day.arrivalLateMinutes <= 0) return Text(day.clockIn!);
  final cut = day.status == AttendanceStatus.hoursCut;
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: day.clockIn),
        TextSpan(
          text: '  ${_duration(day.arrivalLateMinutes)} late',
          style: TextStyle(
            color: cut ? AppColors.error : AppColors.warning,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

/// The clock-out time, with the extra minutes stayed beside it in green.
Widget _clockOut(AttendanceDay day) {
  if (day.clockOut == null) return const Text('');
  if (day.extraMinutes <= 0) return Text(day.clockOut!);
  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: day.clockOut),
        TextSpan(
          text: '  +${_duration(day.extraMinutes)}',
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

String _shortDate(String iso) {
  final parts = iso.split('-');
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// One row per day of the month, in the same columns as the machine
/// software's own report: clock in/out, late, early, work time.
class AttendanceDayTable extends StatelessWidget {
  const AttendanceDayTable({super.key, required this.days, this.onToggleWfh});

  final List<AttendanceDay> days;

  /// When set (HR viewing someone's month), each working day gets a button to
  /// mark it as work from home — or to undo that.
  final void Function(AttendanceDay day)? onToggleWfh;

  /// A small button per working day: mark it as work from home, or undo it.
  Widget _wfhAction(AttendanceDay day) {
    final eligible =
        day.status != AttendanceStatus.weekend &&
        day.status != AttendanceStatus.holiday &&
        day.status != AttendanceStatus.leave;
    if (!eligible) return const SizedBox.shrink();
    final isWfh = day.status == AttendanceStatus.wfh;
    return IconButton(
      key: Key('toggle-wfh-${day.date}'),
      tooltip: isWfh
          ? 'Remove the work-from-home mark'
          : 'Mark as work from home',
      icon: Icon(
        isWfh ? Icons.home : Icons.home_work_outlined,
        size: 18,
        color: isWfh ? AppColors.primary : AppColors.textSecondary,
      ),
      onPressed: () => onToggleWfh!(day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: 28,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            headingRowHeight: 40,
            columns: [
              const DataColumn(label: Text('Date')),
              const DataColumn(label: Text('Day')),
              const DataColumn(label: Text('Clock In')),
              const DataColumn(label: Text('Clock Out')),
              const DataColumn(label: Text('Work'), numeric: true),
              const DataColumn(label: Text('Status')),
              if (onToggleWfh != null) const DataColumn(label: Text('')),
            ],
            rows: [
              for (final day in days)
                DataRow(
                  color: day.status == AttendanceStatus.weekend
                      ? WidgetStatePropertyAll(
                          AppColors.textSecondary.withValues(alpha: 0.06),
                        )
                      : null,
                  cells: [
                    DataCell(Text(_shortDate(day.date))),
                    DataCell(Text(day.weekday, style: muted)),
                    DataCell(_clockIn(day)),
                    DataCell(_clockOut(day)),
                    DataCell(Text(formatAttendanceMinutes(day.workMinutes))),
                    DataCell(() {
                      final (label, color) = _statusLabel(day.status);
                      // A leave day says which kind: Casual, Sick, Annual...
                      final text =
                          day.status == AttendanceStatus.leave &&
                              day.leaveType != null
                          ? day.leaveType!
                          : label;
                      return Text(
                        text,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }()),
                    if (onToggleWfh != null) DataCell(_wfhAction(day)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
