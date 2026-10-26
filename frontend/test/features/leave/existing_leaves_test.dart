import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/presentation/widgets/existing_leaves_notice.dart';
import 'package:zera_erp/features/leave/presentation/widgets/leave_calendar_view.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';

Widget _wrap(FakeLeaveRepository repository, Widget child) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      leaveRepositoryProvider.overrideWithValue(repository),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'tapping a busy day lists everyone on leave, not just the chips',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final iso =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final repository = FakeLeaveRepository(
        calendarEntries: [
          for (final name in ['Ann One', 'Bob Two', 'Cy Three', 'Di Four'])
            buildTestLeaveCalendarEntry(
              employeeId: name,
              employeeName: name,
              startDate: iso,
              endDate: iso,
            ),
        ],
      );
      await tester.pumpWidget(
        _wrap(repository, const LeaveCalendarView(initialScope: 'company')),
      );
      await tester.pumpAndSettle();

      expect(find.text('+2 more'), findsOneWidget);
      await tester.tap(find.byKey(Key('leave-day-${now.day}')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Di Four'), findsOneWidget);
      expect(find.textContaining('Ann One'), findsOneWidget);
    },
  );

  testWidgets('warns about overlapping leave, pending or approved', (
    tester,
  ) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, 15);
    final repository = FakeLeaveRepository(
      calendarEntries: [
        buildTestLeaveCalendarEntry(
          employeeId: 'zahra',
          leaveTypeName: 'Sick Leave',
          startDate: _iso(day),
          endDate: _iso(day),
        ),
        buildTestLeaveCalendarEntry(
          employeeId: 'zahra',
          leaveTypeName: 'Annual Leave',
          startDate: _iso(day),
          endDate: _iso(day),
          isPending: true,
        ),
        buildTestLeaveCalendarEntry(
          employeeId: 'someone-else',
          startDate: _iso(day),
          endDate: _iso(day),
        ),
      ],
    );
    await tester.pumpWidget(
      _wrap(
        repository,
        ExistingLeavesNotice(employeeId: 'zahra', startDate: day, endDate: day),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Already has leave in this period'), findsOneWidget);
    expect(find.textContaining('Sick Leave'), findsOneWidget);
    expect(find.textContaining('(approved)'), findsOneWidget);
    expect(find.textContaining('(awaiting approval)'), findsOneWidget);
  });

  testWidgets('shows nothing when the dates are free', (tester) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, 15);
    await tester.pumpWidget(
      _wrap(
        FakeLeaveRepository(),
        ExistingLeavesNotice(employeeId: 'zahra', startDate: day, endDate: day),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('existing-leaves-notice')), findsNothing);
  });
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
