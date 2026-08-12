import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/upcoming_birthday.dart';
import 'package:zera_erp/features/employee/presentation/widgets/notification_bell.dart';
import 'package:zera_erp/features/leave/application/leave_providers.dart';
import 'package:zera_erp/features/leave/domain/repositories/leave_repository.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/requests/domain/entities/employee_request.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_leave.dart';
import '../../helpers/fake_request.dart';

EmployeeRequest _buildRequest({
  String id = 'request-1',
  String requesterName = 'Ravi Report',
}) {
  return EmployeeRequest(
    id: id,
    requesterId: 'employee-1',
    requesterName: requesterName,
    subject: 'New laptop',
    description: 'My laptop is broken.',
    status: 'submitted',
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository employeeRepository,
  required FakeRequestRepository requestRepository,
  FakeLeaveRepository? leaveRepository,
  ValueChanged<NotificationLinkTarget>? onNavigate,
}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(employeeRepository),
      requestRepositoryProvider.overrideWithValue(requestRepository),
      leaveRepositoryProvider.overrideWithValue(
        leaveRepository ?? FakeLeaveRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: NotificationBell(onNavigate: onNavigate ?? (_) {}),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows a combined badge count and opens birthdays + approvals',
    (tester) async {
      final employeeRepository = FakeEmployeeRepository(
        upcomingBirthdays: const [
          UpcomingBirthday(
            employeeId: 'employee-2',
            fullName: 'Amna Irfan',
            dateOfBirth: '1997-08-13',
            daysUntil: 1,
          ),
        ],
      );
      final requestRepository = FakeRequestRepository(
        pendingHrApproval: [_buildRequest(id: 'request-hr')],
        pendingManagerApproval: [_buildRequest(id: 'request-manager')],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['employees.manage', 'users.manage'],
          employeeRepository: employeeRepository,
          requestRepository: requestRepository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Amna Irfan's birthday"),
        findsOneWidget,
      );
      expect(find.text('Awaiting HR approval'), findsOneWidget);
      expect(find.text('Awaiting your approval'), findsOneWidget);
    },
  );

  testWidgets('tapping an HR-approval item navigates to the admin dashboard', (
    tester,
  ) async {
    NotificationLinkTarget? tapped;
    final requestRepository = FakeRequestRepository(
      pendingHrApproval: [_buildRequest(id: 'request-hr')],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['users.manage'],
        employeeRepository: FakeEmployeeRepository(),
        requestRepository: requestRepository,
        onNavigate: (target) => tapped = target,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awaiting HR approval'));
    await tester.pumpAndSettle();

    expect(tapped, NotificationLinkTarget.adminDashboard);
  });

  testWidgets(
    'tapping a manager-approval item navigates to the user dashboard',
    (tester) async {
      NotificationLinkTarget? tapped;
      final requestRepository = FakeRequestRepository(
        pendingManagerApproval: [_buildRequest(id: 'request-manager')],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: requestRepository,
          onNavigate: (target) => tapped = target,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Awaiting your approval'));
      await tester.pumpAndSettle();

      expect(tapped, NotificationLinkTarget.userDashboard);
    },
  );

  testWidgets(
    'hides birthdays and HR approvals from a viewer without those permissions',
    (tester) async {
      final employeeRepository = FakeEmployeeRepository(
        upcomingBirthdays: const [
          UpcomingBirthday(
            employeeId: 'employee-2',
            fullName: 'Amna Irfan',
            dateOfBirth: '1997-08-13',
            daysUntil: 1,
          ),
        ],
      );
      final requestRepository = FakeRequestRepository(
        pendingHrApproval: [_buildRequest(id: 'request-hr')],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: employeeRepository,
          requestRepository: requestRepository,
        ),
      );
      await tester.pumpAndSettle();

      // Neither the birthday nor the HR-only request count toward the
      // badge — this viewer has no employees.manage or users.manage.
      expect(find.textContaining('+'), findsNothing);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('No notifications right now.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a leave request awaiting HR approval and navigates to Leave',
    (tester) async {
      NotificationLinkTarget? tapped;
      final leaveRepository = FakeLeaveRepository(
        pendingHrApproval: [
          buildTestLeaveRequest(id: 'leave-1', requesterName: 'Amna Irfan'),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: ['leave.manage'],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          leaveRepository: leaveRepository,
          onNavigate: (target) => tapped = target,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Leave awaiting HR approval'), findsOneWidget);
      await tester.tap(find.text('Leave awaiting HR approval'));
      await tester.pumpAndSettle();

      expect(tapped, NotificationLinkTarget.leavePage);
    },
  );

  testWidgets(
    'shows the annual reset reminder for a leave.manage holder',
    (tester) async {
      final leaveRepository = FakeLeaveRepository(
        resetStatus: const LeaveResetStatus(year: 2027, isInitialized: false),
      );

      await tester.pumpWidget(
        _app(
          permissions: ['leave.manage'],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          leaveRepository: leaveRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Annual leave balances for 2027'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows the viewer\'s own recently-decided leave request',
    (tester) async {
      final leaveRepository = FakeLeaveRepository(
        myRequests: [
          buildTestLeaveRequest(
            id: 'leave-mine',
            status: 'approved',
            hrDecisionAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          permissions: const [],
          employeeRepository: FakeEmployeeRepository(),
          requestRepository: FakeRequestRepository(),
          leaveRepository: leaveRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Your leave was approved'), findsOneWidget);
    },
  );
}
