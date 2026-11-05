import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/attendance_providers.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../widgets/attendance_day_table.dart';
import '../../../employee/application/employee_providers.dart';
import '../widgets/attendance_machine_view.dart';
import '../widgets/attendance_wfh_section.dart';

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

enum _View { company, mine, machine }

/// Everyone sees their own month. HR/Admin (`attendance.manage`) also get the
/// company-wide table and the machine setup (sync, shift hours, who is who).
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  _View _view = _View.company;

  AttendancePeriod get _period => (month: _month.month, year: _month.year);

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final canManage =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('attendance.manage');
    final view = canManage ? _view : _View.mine;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (canManage)
                      SegmentedButton<_View>(
                        segments: const [
                          ButtonSegment(
                            value: _View.company,
                            label: Text('Company'),
                          ),
                          ButtonSegment(
                            value: _View.mine,
                            label: Text('My Attendance'),
                          ),
                          ButtonSegment(
                            value: _View.machine,
                            label: Text('Settings'),
                          ),
                        ],
                        selected: {_view},
                        onSelectionChanged: (s) =>
                            setState(() => _view = s.first),
                      ),
                    if (view != _View.machine)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MonthSwitcher(
                            month: _month,
                            onPrevious: () => _shift(-1),
                            onNext: () => _shift(1),
                          ),
                          const SizedBox(width: 8),
                          const _RefreshButton(),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                switch (view) {
                  _View.company => _CompanyView(period: _period),
                  _View.mine => _MyView(period: _period),
                  _View.machine => const AttendanceMachineView(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulls the latest scans from the machine so the numbers are never stale.
/// Open to everyone: the server skips the pull if one just succeeded.
class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton();

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton> {
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(attendanceRepositoryProvider).refresh();
      ref.invalidate(myAttendanceProvider);
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(attendanceSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.skipped
                ? 'Already up to date.'
                : result.inserted == 0
                ? 'Synced — nothing new.'
                : 'Synced — ${result.inserted} new scan(s).',
          ),
        ),
      );
    } on AttendanceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const Key('attendance-refresh'),
      onPressed: _busy ? null : _refresh,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.sync, size: 18),
      label: const Text('Sync now'),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

Future<void> _exportPdf(
  BuildContext context,
  WidgetRef ref, {
  required AttendancePeriod period,
  String? employeeId,
  required String fileName,
}) async {
  try {
    final bytes = await ref
        .read(attendanceRepositoryProvider)
        .downloadPdf(
          month: period.month,
          year: period.year,
          employeeId: employeeId,
        );
    ref.read(attendancePdfSaverProvider)(bytes, fileName);
  } on AttendanceException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

String _pdfName(String prefix, AttendancePeriod p) =>
    '$prefix-${p.year}-${p.month.toString().padLeft(2, '0')}.pdf';

// ---------------------------------------------------------------------------
// My attendance
// ---------------------------------------------------------------------------

class _MyView extends ConsumerWidget {
  const _MyView({required this.period});

  final AttendancePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAttendanceProvider(period));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => FormSection(
        child: Row(
          children: [
            Flexible(
              child: Text(
                error is AttendanceException
                    ? error.message
                    : 'Could not load attendance.',
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(myAttendanceProvider(period)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (attendance) => _EmployeeMonth(
        attendance: attendance,
        trailing: OutlinedButton.icon(
          key: const Key('export-my-attendance-pdf'),
          onPressed: attendance.linked
              ? () => _exportPdf(
                  context,
                  ref,
                  period: period,
                  fileName: _pdfName('Attendance', period),
                )
              : null,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Export PDF'),
        ),
      ),
    );
  }
}

/// Summary tiles plus the day-by-day table for one employee's month.
class _EmployeeMonth extends StatelessWidget {
  const _EmployeeMonth({
    required this.attendance,
    this.trailing,
    this.onToggleWfh,
  });

  final EmployeeAttendance attendance;
  final Widget? trailing;
  final void Function(AttendanceDay day)? onToggleWfh;

  @override
  Widget build(BuildContext context) {
    if (attendance.remote && !attendance.linked) {
      return const FormSection(
        child: Text('Attendance is not tracked for remote work.'),
      );
    }
    if (!attendance.linked) {
      return const FormSection(
        child: Text(
          'Not linked to the attendance machine yet. Ask HR to link your '
          'machine ID.',
        ),
      );
    }
    final s = attendance.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MetricCard(
              label: 'Present',
              value: '${s.present}',
              color: AppColors.success,
              icon: Icons.check_circle_outline,
              dense: true,
            ),
            MetricCard(
              label: 'Late',
              value: '${s.late}',
              color: AppColors.warning,
              icon: Icons.schedule,
              dense: true,
            ),
            MetricCard(
              label: 'Absent',
              value: '${s.absent}',
              color: AppColors.error,
              icon: Icons.event_busy_outlined,
              dense: true,
            ),
            MetricCard(
              label: 'Hours Cut',
              value: formatAttendanceMinutes(
                s.hoursCutMinutes,
                blankZero: false,
              ),
              secondaryValue: s.hoursCutDays == 0
                  ? null
                  : 'over ${s.hoursCutDays} day${s.hoursCutDays == 1 ? '' : 's'}',
              color: AppColors.error,
              icon: Icons.content_cut_outlined,
              dense: true,
            ),
            MetricCard(
              label: 'Late Deduction',
              value:
                  '${s.lateDeductionDays} day${s.lateDeductionDays == 1 ? '' : 's'}',
              color: AppColors.error,
              icon: Icons.money_off_outlined,
              dense: true,
            ),
            MetricCard(
              label: 'On Leave',
              value: '${s.leave}',
              color: AppColors.secondary,
              icon: Icons.beach_access_outlined,
              dense: true,
            ),
            MetricCard(
              label: 'Hours Worked',
              value: formatAttendanceMinutes(s.workMinutes, blankZero: false),
              color: AppColors.primary,
              icon: Icons.timelapse_outlined,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormSection(
          title: 'Daily record',
          trailing: trailing,
          child: AttendanceDayTable(
            days: attendance.days,
            onToggleWfh: onToggleWfh,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Company
// ---------------------------------------------------------------------------

class _CompanyView extends ConsumerStatefulWidget {
  const _CompanyView({required this.period});

  final AttendancePeriod period;

  @override
  ConsumerState<_CompanyView> createState() => _CompanyViewState();
}

class _CompanyViewState extends ConsumerState<_CompanyView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(companyAttendanceProvider(widget.period));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => FormSection(
        child: Row(
          children: [
            const Flexible(child: Text('Could not load attendance.')),
            TextButton(
              onPressed: () =>
                  ref.invalidate(companyAttendanceProvider(widget.period)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (employees) {
        final needle = _query.trim().toLowerCase();
        final visible = needle.isEmpty
            ? employees
            : employees
                  .where(
                    (e) =>
                        e.employeeName.toLowerCase().contains(needle) ||
                        e.employeeCode.toLowerCase().contains(needle),
                  )
                  .toList();
        final linked = employees.where((e) => e.linked).toList();
        final today = _todayCounts(linked);
        final remoteCount = _remoteCount(ref, linked);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricCard(
                  label: 'Employees Tracked',
                  value: '${linked.length} / ${employees.length}',
                  color: AppColors.primary,
                  icon: Icons.fingerprint,
                  dense: true,
                ),
                MetricCard(
                  label: 'In Today',
                  value: '${today.inToday}',
                  color: AppColors.success,
                  icon: Icons.login,
                  dense: true,
                ),
                MetricCard(
                  label: 'Late Today',
                  value: '${today.late}',
                  color: AppColors.warning,
                  icon: Icons.schedule,
                  dense: true,
                ),
                MetricCard(
                  label: 'Absent Today',
                  value: '${today.absent}',
                  color: AppColors.error,
                  icon: Icons.person_off_outlined,
                  dense: true,
                ),
                MetricCard(
                  label: 'Working From Home',
                  value: '${remoteCount + today.workingFromHome}',
                  color: AppColors.primary,
                  icon: Icons.home_work_outlined,
                  dense: true,
                ),
                MetricCard(
                  label: 'Late Days',
                  value: '${linked.fold<int>(0, (a, e) => a + e.summary.late)}',
                  color: AppColors.warning,
                  icon: Icons.schedule,
                  dense: true,
                ),
                MetricCard(
                  label: 'Absent Days',
                  value:
                      '${linked.fold<int>(0, (a, e) => a + e.summary.absent)}',
                  color: AppColors.error,
                  icon: Icons.event_busy_outlined,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const AttendanceWfhSection(),
            const SizedBox(height: 16),
            FormSection(
              title: 'Everyone',
              trailing: OutlinedButton.icon(
                key: const Key('export-company-attendance-pdf'),
                onPressed: () => _exportPdf(
                  context,
                  ref,
                  period: widget.period,
                  fileName: _pdfName('Attendance-All', widget.period),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export PDF'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or code',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No employees match your search.'),
                    )
                  else
                    _CompanyTable(rows: visible, period: widget.period),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Today's headcounts across the tracked employees (only meaningful when
  /// the month on screen is the current one): in, absent (nobody expected
  /// who hasn't shown up and isn't on leave), and marked as work from home.
  ({int inToday, int absent, int late, int workingFromHome}) _todayCounts(
    List<EmployeeAttendance> linked,
  ) {
    final now = DateTime.now();
    if (widget.period.month != now.month || widget.period.year != now.year) {
      return (inToday: 0, absent: 0, late: 0, workingFromHome: 0);
    }
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    var inToday = 0;
    var absent = 0;
    var late = 0;
    var wfh = 0;
    for (final e in linked) {
      final day = e.days.where((d) => d.date == today).firstOrNull;
      if (day == null) continue;
      if (day.clockIn != null) inToday++;
      if (day.arrivalLateMinutes > 0) late++;
      if (day.status == AttendanceStatus.absent ||
          day.status == AttendanceStatus.pending) {
        absent++;
      }
      if (day.status == AttendanceStatus.wfh) wfh++;
    }
    return (inToday: inToday, absent: absent, late: late, workingFromHome: wfh);
  }

  /// Active remote employees who aren't tracked on the machine — people who
  /// work from home all the time.
  int _remoteCount(WidgetRef ref, List<EmployeeAttendance> linked) {
    final everyone = ref.watch(employeeListProvider).valueOrNull;
    if (everyone == null) return 0;
    final trackedIds = {for (final e in linked) e.employeeId};
    return everyone
        .where(
          (e) =>
              e.workMode == 'remote' &&
              e.employmentStatus == 'active' &&
              !trackedIds.contains(e.id),
        )
        .length;
  }
}

class _CompanyTable extends StatelessWidget {
  const _CompanyTable({required this.rows, required this.period});

  final List<EmployeeAttendance> rows;
  final AttendancePeriod period;

  @override
  Widget build(BuildContext context) {
    DataColumn numeric(String label) =>
        DataColumn(label: Text(label), numeric: true);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 28,
            columns: [
              const DataColumn(label: Text('Employee')),
              numeric('Present'),
              numeric('Late'),
              DataColumn(
                label: const Tooltip(
                  message:
                      'One unpaid absence for every 3rd late day '
                      '(every 5th for team leads)',
                  child: Text('Late deduction'),
                ),
                numeric: true,
              ),
              DataColumn(
                label: const Tooltip(
                  message:
                      'Arrived after the cut-off: hours are cut instead of '
                      'a late mark',
                  child: Text('Hours cut'),
                ),
                numeric: true,
              ),
              numeric('Absent'),
              numeric('Leave'),
              numeric('Late time'),
              numeric('Worked'),
            ],
            rows: [
              for (final e in rows)
                DataRow(
                  onSelectChanged: (_) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _EmployeeAttendancePage(
                        attendance: e,
                        period: period,
                      ),
                    ),
                  ),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmployeeAvatar(
                            fullName: e.employeeName,
                            photoUrl: e.profilePhotoUrl,
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.employeeName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                e.linked ? e.employeeCode : 'Not linked',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: e.linked
                                          ? AppColors.textSecondary
                                          : AppColors.warning,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(e.linked ? '${e.summary.present}' : '—')),
                    DataCell(
                      Text(
                        e.linked ? '${e.summary.late}' : '—',
                        style: TextStyle(
                          color: e.linked && e.summary.late > 0
                              ? AppColors.warning
                              : null,
                          fontWeight: e.linked && e.summary.late > 0
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        e.linked
                            ? (e.summary.lateDeductionDays == 0
                                  ? '0'
                                  : '${e.summary.lateDeductionDays} day'
                                        '${e.summary.lateDeductionDays == 1 ? '' : 's'}')
                            : '—',
                        style: TextStyle(
                          color: e.linked && e.summary.lateDeductionDays > 0
                              ? AppColors.error
                              : null,
                          fontWeight:
                              e.linked && e.summary.lateDeductionDays > 0
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: e.summary.hoursCutDays == 0
                            ? 'No hours cut'
                            : 'Hours cut over ${e.summary.hoursCutDays} '
                                  'day${e.summary.hoursCutDays == 1 ? '' : 's'}',
                        child: Text(
                          e.linked
                              ? formatAttendanceMinutes(
                                  e.summary.hoursCutMinutes,
                                  blankZero: false,
                                )
                              : '—',
                          style: TextStyle(
                            color: e.linked && e.summary.hoursCutDays > 0
                                ? AppColors.error
                                : null,
                            fontWeight: e.linked && e.summary.hoursCutDays > 0
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        e.linked ? '${e.summary.absent}' : '—',
                        style: TextStyle(
                          color: e.linked && e.summary.absent > 0
                              ? AppColors.error
                              : null,
                        ),
                      ),
                    ),
                    DataCell(Text(e.linked ? '${e.summary.leave}' : '—')),
                    DataCell(
                      Text(
                        e.linked
                            ? formatAttendanceMinutes(
                                e.summary.lateMinutes,
                                blankZero: false,
                              )
                            : '—',
                        style: TextStyle(
                          color: e.linked && e.summary.lateMinutes > 0
                              ? AppColors.warning
                              : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        e.linked
                            ? formatAttendanceMinutes(
                                e.summary.workMinutes,
                                blankZero: false,
                              )
                            : '—',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One employee's month, opened from the company table. It watches the live
/// company data, so marking a day as work from home updates it at once.
class _EmployeeAttendancePage extends ConsumerWidget {
  const _EmployeeAttendancePage({
    required this.attendance,
    required this.period,
  });

  final EmployeeAttendance attendance;
  final AttendancePeriod period;

  Future<void> _toggleWfh(
    BuildContext context,
    WidgetRef ref,
    EmployeeAttendance current,
    AttendanceDay day,
  ) async {
    final repository = ref.read(attendanceRepositoryProvider);
    try {
      if (day.status == AttendanceStatus.wfh) {
        await repository.unmarkEmployeeWfh(
          employeeId: current.employeeId,
          date: day.date,
        );
      } else {
        await repository.markEmployeeWfh(
          employeeId: current.employeeId,
          date: day.date,
        );
      }
      ref.invalidate(companyAttendanceProvider);
      ref.invalidate(wfhDaysProvider);
    } on AttendanceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref
        .watch(companyAttendanceProvider(period))
        .valueOrNull
        ?.where((e) => e.employeeId == attendance.employeeId)
        .firstOrNull;
    final current = live ?? attendance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${current.employeeName} — '
          '${_monthNames[period.month - 1]} ${period.year}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: _EmployeeMonth(
              attendance: current,
              onToggleWfh: (day) => _toggleWfh(context, ref, current, day),
              trailing: OutlinedButton.icon(
                onPressed: () => _exportPdf(
                  context,
                  ref,
                  period: period,
                  employeeId: current.employeeId,
                  fileName: _pdfName(
                    'Attendance-${current.employeeName.replaceAll(' ', '-')}',
                    period,
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export PDF'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
