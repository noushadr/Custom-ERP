import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/theme/app_colors.dart';
import 'package:zera_erp/shared/widgets/metric_card.dart';
import 'package:zera_erp/features/attendance/application/attendance_providers.dart';
import 'package:zera_erp/features/attendance/domain/entities/attendance.dart';
import 'package:zera_erp/features/attendance/domain/exceptions/attendance_exception.dart';
import 'package:zera_erp/features/attendance/presentation/pages/attendance_page.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';

import '../../helpers/fake_attendance.dart';
import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app(
  FakeAttendanceRepository repository, {
  List<String> permissions = const [],
  List<List<int>>? savedPdfs,
  FakeEmployeeRepository? employeeRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(
            AuthUser(
              id: testAuthUser.id,
              email: testAuthUser.email,
              role: testAuthUser.role,
              permissions: permissions,
            ),
          ),
        ),
      ),
      attendanceRepositoryProvider.overrideWithValue(repository),
      attendancePdfSaverProvider.overrideWithValue(
        (bytes, fileName) => savedPdfs?.add(bytes),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: AttendancePage())),
  );
}

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('an employee sees their own month in the report columns', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(
        days: [
          buildTestAttendanceDay(),
          buildTestAttendanceDay(
            date: '2026-10-06',
            weekday: 'Tue',
            clockIn: '11:40',
            clockOut: '19:00',
            lateMinutes: 40,
            earlyMinutes: 0,
            workMinutes: 440,
            status: AttendanceStatus.late,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Daily record'), findsOneWidget);
    expect(find.text('05/10/2026'), findsOneWidget);
    expect(find.text('10:42'), findsOneWidget);
    expect(find.text('18:26'), findsOneWidget);
    expect(find.text('Late'), findsWidgets);
    // No HR controls for a plain employee.
    expect(find.text('Company'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('everyone has a Sync now button that pulls the latest scans', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('attendance-refresh')));
    await tester.pumpAndSettle();

    expect(repository.refreshCalls, 1);
    expect(find.text('Synced — 2 new scan(s).'), findsOneWidget);
  });

  testWidgets('the company view has Sync now too', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      company: [buildTestEmployeeAttendance()],
    );
    await tester.pumpWidget(
      _app(repository, permissions: const ['attendance.manage']),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('attendance-refresh')));
    await tester.pumpAndSettle();

    expect(repository.refreshCalls, 1);
  });

  testWidgets('a leave day names the kind of leave', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(
        days: [
          buildTestAttendanceDay(
            date: '2026-10-06',
            weekday: 'Tue',
            clockIn: null,
            clockOut: null,
            earlyMinutes: 0,
            workMinutes: 0,
            status: AttendanceStatus.leave,
            leaveType: 'Sick Leave',
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Sick Leave'), findsOneWidget);
  });

  testWidgets('a very late arrival is shown as Hours cut with the time cut', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(
        days: [
          buildTestAttendanceDay(
            date: '2026-10-06',
            weekday: 'Tue',
            clockIn: '12:10',
            clockOut: '19:00',
            earlyMinutes: 0,
            workMinutes: 410,
            status: AttendanceStatus.hoursCut,
          ),
        ],
        summary: const AttendanceSummary(
          present: 1,
          late: 0,
          absent: 0,
          leave: 0,
          incomplete: 0,
          hoursCutDays: 1,
          hoursCutMinutes: 60,
          lateMinutes: 0,
          workMinutes: 410,
        ),
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Hours cut'), findsOneWidget); // the day's status
    expect(find.text('Hours Cut'), findsOneWidget); // the tile
    // Just the hours cut, with the days underneath in plain words.
    expect(find.text('1hr'), findsWidgets);
    expect(find.text('over 1 day'), findsOneWidget);
  });

  testWidgets('the company table has an Hours cut column', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      company: [
        buildTestEmployeeAttendance(
          employeeName: 'Late Larry',
          summary: const AttendanceSummary(
            present: 5,
            late: 1,
            absent: 0,
            leave: 0,
            incomplete: 0,
            hoursCutDays: 2,
            hoursCutMinutes: 180,
            lateMinutes: 20,
            workMinutes: 0,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      _app(repository, permissions: const ['attendance.manage']),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hours cut'), findsOneWidget); // the column header
    expect(find.text('3hr'), findsOneWidget);
  });

  testWidgets('says so when the employee is not linked to the machine yet', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(linked: false),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Not linked to the attendance machine'),
      findsOneWidget,
    );
  });

  testWidgets('says attendance is not tracked for remote work', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(linked: false, remote: true),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Attendance is not tracked for remote work.'),
      findsOneWidget,
    );
    expect(find.textContaining('Ask HR to link'), findsNothing);
  });

  testWidgets('shows the reason when the month cannot load, with Retry', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mineError: const AttendanceException(
        'No attendance record for this profile.',
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('No attendance record for this profile.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Export PDF downloads the employee\'s own month', (tester) async {
    await _useTallSurface(tester);
    final saved = <List<int>>[];
    final repository = FakeAttendanceRepository();
    await tester.pumpWidget(_app(repository, savedPdfs: saved));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('export-my-attendance-pdf')));
    await tester.pumpAndSettle();

    expect(repository.pdfCalls, 1);
    expect(repository.lastPdfEmployeeId, isNull);
    expect(saved, hasLength(1));
  });

  testWidgets('HR can hide a former employee from the machine list', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mapping: const [
        AttendanceMapping(
          deviceUserId: '15',
          deviceName: 'Old Timer',
          employeeId: null,
          employeeName: null,
        ),
        AttendanceMapping(
          deviceUserId: '16',
          deviceName: 'Gone Already',
          employeeId: null,
          employeeName: null,
          ignored: true,
        ),
      ],
    );
    await tester.pumpWidget(
      _app(repository, permissions: const ['attendance.manage']),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Old Timer'), findsOneWidget);
    expect(find.text('Gone Already'), findsNothing);
    expect(find.text('No longer at Zera (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ignore-15')));
    await tester.pumpAndSettle();
    expect(repository.lastIgnoredDeviceUserId, '15');
    expect(repository.lastIgnoredValue, isTrue);

    await tester.tap(find.text('No longer at Zera (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restore-16')));
    await tester.pumpAndSettle();
    expect(repository.lastIgnoredDeviceUserId, '16');
    expect(repository.lastIgnoredValue, isFalse);
  });

  testWidgets('a work from home day reads as Work from home, with no times', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(
        days: [
          buildTestAttendanceDay(
            date: '2026-11-12',
            weekday: 'Thu',
            clockIn: null,
            clockOut: null,
            earlyMinutes: 0,
            workMinutes: 0,
            status: AttendanceStatus.wfh,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Work from home'), findsOneWidget);
  });

  testWidgets('daily table shows how late after clock in, and extra time out', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(
        days: [
          buildTestAttendanceDay(
            date: '2026-10-06',
            weekday: 'Tue',
            clockIn: '11:25',
            clockOut: '19:40',
            lateMinutes: 25,
            arrivalLateMinutes: 25,
            extraMinutes: 40,
            earlyMinutes: 0,
            status: AttendanceStatus.late,
          ),
          buildTestAttendanceDay(
            date: '2026-10-07',
            weekday: 'Wed',
            clockIn: '12:40',
            clockOut: '19:00',
            arrivalLateMinutes: 100,
            earlyMinutes: 0,
            status: AttendanceStatus.hoursCut,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('25m late', findRichText: true), findsOneWidget);
    // Lateness lives beside the clock-in time, not in its own column.
    expect(find.widgetWithText(DataColumn, 'Late'), findsNothing);
    expect(find.text('Early'), findsNothing);
    expect(find.textContaining('+40m', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('1hr 40m late', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets(
    'the company view counts who is in, absent and working from home',
    (tester) async {
      await _useTallSurface(tester);
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      EmployeeAttendance person(String id, AttendanceDay day) =>
          buildTestEmployeeAttendance(
            employeeId: id,
            employeeName: 'Person $id',
            days: [day],
          );
      AttendanceDay todayWith(String status, {String? clockIn}) =>
          buildTestAttendanceDay(
            date: today,
            clockIn: clockIn,
            clockOut: null,
            status: status,
          );
      final repository = FakeAttendanceRepository(
        company: [
          person(
            'a',
            buildTestAttendanceDay(
              date: today,
              clockIn: '11:25',
              clockOut: null,
              arrivalLateMinutes: 25,
              lateMinutes: 25,
              status: AttendanceStatus.late,
            ),
          ),
          person('b', todayWith(AttendanceStatus.pending)),
          person('c', todayWith(AttendanceStatus.wfh)),
        ],
      );
      await tester.pumpWidget(
        _app(
          repository,
          permissions: const ['attendance.manage'],
          employeeRepository: FakeEmployeeRepository(
            employees: [
              buildTestEmployee(id: 'r1', workMode: 'remote'),
              buildTestEmployee(
                id: 'r2',
                fullName: 'Rita Remote',
                workMode: 'remote',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      Finder tile(String label, String value) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(MetricCard),
        ),
        matching: find.text(value),
      );
      expect(tile('In Today', '1'), findsOneWidget);
      expect(tile('Late Today', '1'), findsOneWidget);
      expect(tile('Absent Today', '1'), findsOneWidget);
      // Two remote employees plus the one marked work from home today.
      expect(tile('Working From Home', '3'), findsOneWidget);
    },
  );

  testWidgets('HR can mark one person\'s day as work from home', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      company: [
        buildTestEmployeeAttendance(
          employeeId: 'e1',
          employeeName: 'Babar Hussain',
          days: [
            buildTestAttendanceDay(date: '2026-10-06', weekday: 'Tue'),
            buildTestAttendanceDay(
              date: '2026-10-07',
              weekday: 'Wed',
              clockIn: null,
              clockOut: null,
              earlyMinutes: 0,
              workMinutes: 0,
              status: AttendanceStatus.wfh,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _app(repository, permissions: const ['attendance.manage']),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Babar Hussain'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('toggle-wfh-2026-10-06')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-wfh-2026-10-06')));
    await tester.pumpAndSettle();
    expect(repository.lastMarkedWfhEmployeeId, 'e1');
    expect(repository.lastMarkedWfhEmployeeDate, '2026-10-06');

    await tester.ensureVisible(find.byKey(const Key('toggle-wfh-2026-10-07')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-wfh-2026-10-07')));
    await tester.pumpAndSettle();
    expect(repository.lastUnmarkedWfhEmployeeDate, '2026-10-07');
  });

  group('work from home days (HR)', () {
    final team = [
      const WfhDayEmployee(
        employeeId: 'e1',
        employeeName: 'Babar Hussain',
        employeeCode: 'ZC-039',
        present: true,
      ),
      const WfhDayEmployee(
        employeeId: 'e2',
        employeeName: 'Aamna Irfan',
        employeeCode: 'ZC-064',
        present: false,
      ),
    ];

    Future<FakeAttendanceRepository> openCompany(WidgetTester tester) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(
        wfhDays: const [
          WfhDay(date: '2026-11-12', note: 'Power cut', presentCount: 1),
        ],
        wfhEmployees: team,
      );
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('lists the days with who was marked present', (tester) async {
      await openCompany(tester);

      expect(find.text('Work from home days'), findsOneWidget);
      expect(find.textContaining('Power cut'), findsOneWidget);
      expect(find.textContaining('1 marked present'), findsOneWidget);
    });

    testWidgets('HR can tick who worked and save it', (tester) async {
      final repository = await openCompany(tester);

      await tester.tap(find.byKey(const Key('mark-wfh-2026-11-12')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 worked'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wfh-select-all')));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2 worked'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wfh-save')));
      await tester.pumpAndSettle();

      expect(repository.lastMarkedWfhDate, '2026-11-12');
      expect(repository.lastMarkedWfhEmployeeIds, containsAll(['e1', 'e2']));
    });

    testWidgets('HR can remove a work from home day', (tester) async {
      final repository = await openCompany(tester);

      await tester.tap(find.byKey(const Key('remove-wfh-2026-11-12')));
      await tester.pumpAndSettle();

      expect(repository.lastRemovedWfhDate, '2026-11-12');
    });
  });

  group('HR / Admin', () {
    final company = [
      buildTestEmployeeAttendance(
        employeeId: 'e1',
        employeeName: 'Babar Hussain',
        summary: const AttendanceSummary(
          present: 18,
          late: 7,
          lateDeductionDays: 2,
          absent: 1,
          leave: 0,
          incomplete: 0,
          lateMinutes: 95,
          workMinutes: 9000,
        ),
      ),
      buildTestEmployeeAttendance(
        employeeId: 'e2',
        employeeName: 'Ali Unlinked',
        linked: false,
      ),
    ];

    testWidgets('see everyone in a table, with unlinked people flagged', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(company: company);
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();

      expect(find.text('Babar Hussain'), findsOneWidget);
      expect(find.text('Ali Unlinked'), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('1hr 35m'), findsOneWidget);
    });

    testWidgets('late days are highlighted in yellow', (tester) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(company: company);
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();

      final late = tester.widget<Text>(
        find.descendant(of: find.byType(DataTable), matching: find.text('7')),
      );
      expect(late.style?.color, AppColors.warning);

      // Seven lates cost two unpaid days — a third late day each.
      final deduction = tester.widget<Text>(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('2 days'),
        ),
      );
      expect(deduction.style?.color, AppColors.error);
    });

    testWidgets('can search the table and open one person\'s month', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(company: company);
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Search by name or code'),
        'babar',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ali Unlinked'), findsNothing);

      await tester.tap(find.text('Babar Hussain'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Babar Hussain —'), findsOneWidget);
      expect(find.text('Daily record'), findsOneWidget);
    });

    testWidgets('Export PDF in the company view asks for everyone', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(company: company);
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-company-attendance-pdf')));
      await tester.pumpAndSettle();

      expect(repository.pdfCalls, 1);
      expect(repository.lastPdfEmployeeId, isNull);
    });

    testWidgets('the Machine tab syncs, auto-links and saves working hours', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repository = FakeAttendanceRepository(
        company: company,
        mapping: const [
          AttendanceMapping(
            deviceUserId: '48',
            deviceName: 'Suleman',
            employeeId: null,
            employeeName: null,
          ),
        ],
      );
      await tester.pumpWidget(
        _app(repository, permissions: const ['attendance.manage']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Suleman'), findsOneWidget);

      await tester.tap(find.byKey(const Key('attendance-sync')));
      await tester.pumpAndSettle();
      expect(repository.syncCalls, 1);

      await tester.tap(find.byKey(const Key('attendance-auto-link')));
      await tester.pumpAndSettle();
      expect(repository.autoMapCalls, 1);

      await tester.enterText(
        find.widgetWithText(TextField, 'Shift starts'),
        '10:00',
      );
      await tester.tap(find.byKey(const Key('attendance-save-settings')));
      await tester.pumpAndSettle();
      expect(repository.savedSettings?.shiftStart, '10:00');
    });
  });
}
