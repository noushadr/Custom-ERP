import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/attendance.dart';

(String, Color?) _statusLabel(String status) => switch (status) {
  AttendanceStatus.present => ('Present', AppColors.success),
  AttendanceStatus.late => ('Late', AppColors.warning),
  AttendanceStatus.incomplete => ('No check-out', AppColors.warning),
  AttendanceStatus.absent => ('Absent', AppColors.error),
  AttendanceStatus.leave => ('Leave', AppColors.secondary),
  AttendanceStatus.holiday => ('Holiday', AppColors.accentTeal),
  AttendanceStatus.weekend => ('Weekend', AppColors.textSecondary),
  _ => ('', null),
};

String _shortDate(String iso) {
  final parts = iso.split('-');
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// One row per day of the month, in the same columns as the machine
/// software's own report: clock in/out, late, early, work time.
class AttendanceDayTable extends StatelessWidget {
  const AttendanceDayTable({super.key, required this.days});

  final List<AttendanceDay> days;

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
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Day')),
              DataColumn(label: Text('Clock In')),
              DataColumn(label: Text('Clock Out')),
              DataColumn(label: Text('Late'), numeric: true),
              DataColumn(label: Text('Early'), numeric: true),
              DataColumn(label: Text('Work'), numeric: true),
              DataColumn(label: Text('Status')),
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
                    DataCell(Text(day.clockIn ?? '')),
                    DataCell(Text(day.clockOut ?? '')),
                    DataCell(Text(formatAttendanceMinutes(day.lateMinutes))),
                    DataCell(Text(formatAttendanceMinutes(day.earlyMinutes))),
                    DataCell(Text(formatAttendanceMinutes(day.workMinutes))),
                    DataCell(() {
                      final (label, color) = _statusLabel(day.status);
                      return Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
