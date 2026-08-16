import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/holidays/application/holiday_providers.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/domain/repositories/leave_repository.dart';
import 'package:zera_erp/features/leave/presentation/pages/leave_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_holiday.dart';
import '../../helpers/fake_leave.dart';

AuthUser _viewer({String role = 'Employee', List<String> permissions = const []}) =>
    AuthUser(
      id: 'user-1',
      email: 'jane.doe@zeracreative.com',
      role: role,
      permissions: permissions,
    );

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  String role = 'Employee',
  List<String> permissions = const [],
  FakeLeaveRepository? leaveRepository,
  FakeHolidayRepository? holidayRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(_viewer(role: role, permissions: permissions)),
        ),
      ),
      leaveRepositoryProvider.overrideWithValue(
        leaveRepository ?? FakeLeaveRepository(),
      ),
      // LeavePage embeds LeaveCalendarView, which checks department headship
      // to decide whether to show the "My Team" toggle — no test in this
      // file cares about that, so a plain, deterministic fake avoids a real
      // network call for myProfileProvider/departmentsProvider.
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
      // The apply-leave dialog previews the working-day count against
      // configured holidays — default to none so tests stay deterministic.
      holidayRepositoryProvider.overrideWithValue(
        holidayRepository ?? FakeHolidayRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: LeavePage())),
  );
}

void main() {
  testWidgets('shows current leave balances as cards', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        leaveRepository: FakeLeaveRepository(
          myBalances: [
            buildTestLeaveBalance(
              leaveTypeName: 'Annual Leave',
              allocated: 20.5,
              used: 5,
              remaining: 15.5,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('15.5'), findsOneWidget);
    expect(find.text('remaining of 20.5'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no leave balances', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No leave balances yet.'), findsOneWidget);
  });

  testWidgets(
    'previews the working-day count once both dates are selected',
    (tester) async {
      await _useTallSurface(tester);
      final leaveRepository = FakeLeaveRepository(
        leaveTypes: [buildTestLeaveType(id: 'type-1', name: 'Casual Leave')],
      );
      await tester.pumpWidget(_app(leaveRepository: leaveRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply for leave'));
      await tester.pumpAndSettle();

      expect(find.textContaining('selected'), findsNothing);
      expect(find.textContaining('No working days'), findsNothing);

      await tester.tap(find.byKey(const Key('leave-start-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leave-end-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Start == end == "today" here, since both date pickers were confirmed
      // without picking a different day. Whether that lands on a working day
      // depends on which day of the week the suite happens to run — assert
      // the label's shape rather than an exact count so this stays stable.
      final label = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (RegExp(r'^\d+ working days? selected$').hasMatch(widget.data ?? '') ||
                widget.data == 'No working days in this range'),
      );
      expect(label, findsOneWidget);
    },
  );

  testWidgets('submitting a leave request calls the repository', (tester) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      leaveTypes: [buildTestLeaveType(id: 'type-1', name: 'Casual Leave')],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply for leave'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casual Leave').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('leave-start-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('leave-end-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Family event',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(leaveRepository.lastSubmittedLeaveTypeId, 'type-1');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows a validation error when dates are missing', (tester) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      leaveTypes: [buildTestLeaveType(id: 'type-1', name: 'Casual Leave')],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply for leave'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casual Leave').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Family event',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Please fill in every field.'), findsOneWidget);
    expect(leaveRepository.lastSubmittedLeaveTypeId, isNull);
  });

  testWidgets('cancelling a pending leave request calls the repository', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      myRequests: [buildTestLeaveRequest(id: 'request-1', status: 'submitted')],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(leaveRepository.lastCancelledRequestId, 'request-1');
  });

  testWidgets('approving a pending request prompts for a comment and calls approveAsManager', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      pendingManagerApproval: [
        buildTestLeaveRequest(id: 'request-1', requesterName: 'Babar Hussain'),
      ],
    );
    await tester.pumpWidget(_app(leaveRepository: leaveRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Enjoy your trip!');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      ),
    );
    await tester.pumpAndSettle();

    expect(leaveRepository.lastDecidedRequestId, 'request-1');
    expect(leaveRepository.lastDecisionApproved, isTrue);
    expect(leaveRepository.lastDecisionComment, 'Enjoy your trip!');
  });

  testWidgets('hides the HR approval section from a viewer without leave.manage', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(
      _app(
        leaveRepository: FakeLeaveRepository(
          pendingHrApproval: [buildTestLeaveRequest(id: 'request-hr')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leave Requests Awaiting HR Approval'), findsNothing);
  });

  testWidgets('HR/Admin can approve a request awaiting HR approval', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final leaveRepository = FakeLeaveRepository(
      pendingHrApproval: [
        buildTestLeaveRequest(id: 'request-hr', requesterName: 'Amna Irfan'),
      ],
    );
    await tester.pumpWidget(
      _app(permissions: ['leave.manage'], leaveRepository: leaveRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leave Requests Awaiting HR Approval'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      ),
    );
    await tester.pumpAndSettle();

    expect(leaveRepository.lastDecidedRequestId, 'request-hr');
    expect(leaveRepository.lastDecisionApproved, isTrue);
  });

  testWidgets(
    'shows the reset reminder for leave.manage and triggers the reset',
    (tester) async {
      await _useTallSurface(tester);
      final leaveRepository = FakeLeaveRepository(
        resetStatus: const LeaveResetStatus(year: 2026, isInitialized: false),
      );
      await tester.pumpWidget(
        _app(permissions: ['leave.manage'], leaveRepository: leaveRepository),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Annual leave balances for 2026 haven't"),
        findsOneWidget,
      );

      await tester.tap(find.text('Reset now'));
      await tester.pumpAndSettle();

      expect(leaveRepository.resetTriggered, isTrue);
    },
  );

  testWidgets(
    'hides the reset reminder once balances are initialized',
    (tester) async {
      await _useTallSurface(tester);
      await tester.pumpWidget(
        _app(
          permissions: ['leave.manage'],
          leaveRepository: FakeLeaveRepository(
            resetStatus: const LeaveResetStatus(year: 2026, isInitialized: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset now'), findsNothing);
    },
  );
}
