import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Machine & Settings'), findsNothing);
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

    expect(find.textContaining('Not linked to the attendance machine'), findsOneWidget);
  });

  testWidgets('says attendance is not tracked for remote work', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mine: buildTestEmployeeAttendance(linked: false, remote: true),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Attendance is not tracked for remote work.'), findsOneWidget);
    expect(find.textContaining('Ask HR to link'), findsNothing);
  });

  testWidgets('shows the reason when the month cannot load, with Retry', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = FakeAttendanceRepository(
      mineError: const AttendanceException('No attendance record for this profile.'),
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
    await tester.tap(find.text('Machine & Settings'));
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

  group('HR / Admin', () {
    final company = [
      buildTestEmployeeAttendance(
        employeeId: 'e1',
        employeeName: 'Babar Hussain',
        summary: const AttendanceSummary(
          present: 18,
          late: 2,
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
      expect(find.text('01:35'), findsOneWidget);
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

      await tester.tap(find.text('Machine & Settings'));
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
