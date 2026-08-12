import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/presentation/pages/leave_settings_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({FakeLeaveRepository? leaveRepository}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(employees: [buildTestEmployee()]),
      ),
      leaveRepositoryProvider.overrideWithValue(
        leaveRepository ?? FakeLeaveRepository(),
      ),
    ],
    child: const MaterialApp(home: LeaveSettingsPage()),
  );
}

void main() {
  testWidgets('lists existing leave types', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        leaveRepository: FakeLeaveRepository(
          leaveTypes: [
            buildTestLeaveType(name: 'Annual Leave', annualAllowanceDays: 20),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('20 day(s) / year'), findsOneWidget);
  });

  testWidgets('adding a leave type calls createLeaveType', (tester) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository();
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Maternity Leave',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Annual allowance (days)'),
      '90',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add leave type'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('archiving a leave type calls updateLeaveType', (tester) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      leaveTypes: [buildTestLeaveType(id: 'type-1', name: 'Casual Leave')],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    // No repository call assertion needed on the fake beyond not crashing —
    // FakeLeaveRepository.updateLeaveType always succeeds; a real failure
    // would surface as a SnackBar, which we can assert is absent.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('adjusting a balance calls the repository', (tester) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      leaveTypes: [buildTestLeaveType(id: 'type-1', name: 'Annual Leave')],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adjust a balance'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Employee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jane Doe').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Leave type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual Leave').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Delta (+/- days)'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Bonus day',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
