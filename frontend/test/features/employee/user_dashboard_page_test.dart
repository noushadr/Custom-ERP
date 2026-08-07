import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/user_dashboard_page.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/notices/domain/entities/notice.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_notice.dart';
import '../../helpers/fake_request.dart';

const _viewer = AuthUser(
  id: 'user-1',
  email: 'jane.doe@zeracreative.com',
  role: 'Employee',
  permissions: [],
);

Widget _app({
  FakeEmployeeRepository? employeeRepository,
  FakeNoticeRepository? noticeRepository,
  FakeRequestRepository? requestRepository,
  FakeAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          const AuthAuthenticated(_viewer),
          repository: authRepository,
        ),
      ),
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
      noticeRepositoryProvider.overrideWithValue(
        noticeRepository ?? FakeNoticeRepository(),
      ),
      requestRepositoryProvider.overrideWithValue(
        requestRepository ?? FakeRequestRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: UserDashboardPage())),
  );
}

void main() {
  testWidgets(
    'shows a friendly message when the viewer has no employee profile',
    (tester) async {
      await tester.pumpWidget(
        _app(
          employeeRepository: FakeEmployeeRepository(
            getMeError: const EmployeeException('Not found.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining("isn't linked to an employee profile"),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows company notices from the feed', (tester) async {
    await tester.pumpWidget(
      _app(
        noticeRepository: FakeNoticeRepository(
          notices: [
            Notice(
              id: 'notice-1',
              title: 'Office closed',
              body: 'Closed for the holiday.',
              authorName: 'HR Team',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office closed'), findsOneWidget);
    expect(find.text('Closed for the holiday.'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no notices', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No company notices yet.'), findsOneWidget);
  });

  testWidgets('submitting a new request calls the repository', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository();
    await tester.pumpWidget(_app(requestRepository: requestRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New request'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Subject'),
      'Need a new chair',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Mine is broken.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(requestRepository.lastSubmittedSubject, 'Need a new chair');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('changing password calls the auth controller', (tester) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(_app(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'old-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password-123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(authRepository.lastChangePasswordNewPassword, 'new-password-123');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('shows a validation error when the new passwords do not match', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(_app(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'old-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'does-not-match',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(authRepository.lastChangePasswordNewPassword, isNull);
  });

  testWidgets('shows team members assigned to the viewer', (tester) async {
    await tester.pumpWidget(
      _app(
        employeeRepository: FakeEmployeeRepository(
          directReports: [buildTestEmployee(fullName: 'Ravi Report')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ravi Report'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no team members', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('No team members are assigned to you yet.'),
      findsOneWidget,
    );
  });

  testWidgets('approving a pending request calls approveAsManager', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository(
      pendingManagerApproval: [
        buildTestRequest(id: 'request-1', subject: 'Time off'),
      ],
    );
    await tester.pumpWidget(_app(requestRepository: requestRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(requestRepository.lastDecidedRequestId, 'request-1');
    expect(requestRepository.lastDecisionApproved, isTrue);
  });
}
