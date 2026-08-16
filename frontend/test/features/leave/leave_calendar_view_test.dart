import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/presentation/widgets/leave_calendar_view.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';

/// [isDepartmentHead] simulates the viewer heading `dept-1` (the default
/// department id [buildTestEmployee] belongs to) — the "My Team" toggle
/// only renders for department heads.
Widget _app(
  FakeLeaveRepository leaveRepository, {
  bool isDepartmentHead = true,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      leaveRepositoryProvider.overrideWithValue(leaveRepository),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(
          departments: isDepartmentHead
              ? [
                  const Department(
                    id: 'dept-1',
                    name: 'Engineering',
                    headEmployeeId: 'employee-1',
                  ),
                ]
              : const [],
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: LeaveCalendarView()),
      ),
    ),
  );
}

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders an entry inside the day it falls on', (tester) async {
    await _useTallSurface(tester);
    // The widget defaults to viewing the current real-world month, so the
    // fixture must fall within it rather than a fixed calendar date.
    final today = DateTime.now();
    final isoToday =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final leaveRepository = FakeLeaveRepository(
      calendarEntries: [
        buildTestLeaveCalendarEntry(
          employeeName: 'Babar Hussain',
          startDate: isoToday,
          endDate: isoToday,
        ),
      ],
    );
    await tester.pumpWidget(_app(leaveRepository));
    await tester.pumpAndSettle();

    expect(find.text('Babar'), findsOneWidget);
    expect(leaveRepository.lastCalendarScope, 'team');
  });

  testWidgets('switching to Company scope refetches with the new scope', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository();
    await tester.pumpWidget(_app(leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();

    expect(leaveRepository.lastCalendarScope, 'company');
  });

  testWidgets(
    'hides the My Team toggle and always queries company scope for a non-department-head',
    (tester) async {
      await _useTallSurface(tester);
      final leaveRepository = FakeLeaveRepository();
      await tester.pumpWidget(_app(leaveRepository, isDepartmentHead: false));
      await tester.pumpAndSettle();

      expect(find.text('My Team'), findsNothing);
      expect(find.text('Company'), findsNothing);
      expect(leaveRepository.lastCalendarScope, 'company');
    },
  );

  testWidgets('the next-month arrow advances the displayed month', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final leaveRepository = FakeLeaveRepository();
    await tester.pumpWidget(_app(leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '${_monthName(nextMonth.month)} ${nextMonth.year}',
      ),
      findsOneWidget,
    );
  });
}

String _monthName(int month) => const [
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
][month - 1];
