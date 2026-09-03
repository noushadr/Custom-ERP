import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_avatar.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/requests/presentation/pages/requests_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_request.dart';

AuthUser _viewer({String role = 'Employee', List<String> permissions = const []}) =>
    AuthUser(
      id: 'user-1',
      email: 'jane.doe@zeracreative.com',
      role: role,
      permissions: permissions,
    );

Widget _app({
  String role = 'Employee',
  List<String> permissions = const [],
  FakeRequestRepository? requestRepository,
  FakeEmployeeRepository? employeeRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(_viewer(role: role, permissions: permissions)),
        ),
      ),
      requestRepositoryProvider.overrideWithValue(
        requestRepository ?? FakeRequestRepository(),
      ),
      // RequestsPage checks department headship (same as LeaveCalendarView)
      // to decide whether to show the manager-approval section — default to
      // a plain, deterministic fake so tests that don't care about that
      // don't hit a real network call for myProfileProvider/departmentsProvider.
      employeeRepositoryProvider.overrideWithValue(
        employeeRepository ?? FakeEmployeeRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: RequestsPage())),
  );
}

void main() {
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

  testWidgets('approving a pending request calls approveAsManager', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository(
      pendingManagerApproval: [
        buildTestRequest(id: 'request-1', subject: 'Time off'),
      ],
    );
    await tester.pumpWidget(
      _app(role: 'Team Lead', requestRepository: requestRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(requestRepository.lastDecidedRequestId, 'request-1');
    expect(requestRepository.lastDecisionApproved, isTrue);
  });

  testWidgets(
    'hides the manager approval section from a plain employee',
    (tester) async {
      await tester.pumpWidget(
        _app(
          requestRepository: FakeRequestRepository(
            pendingManagerApproval: [buildTestRequest(id: 'request-1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requests Awaiting My Approval'), findsNothing);
    },
  );

  testWidgets(
    'shows the manager approval section for an actual department head',
    (tester) async {
      final requestRepository = FakeRequestRepository(
        pendingManagerApproval: [
          buildTestRequest(id: 'request-1', subject: 'Time off'),
        ],
      );
      await tester.pumpWidget(
        _app(
          requestRepository: requestRepository,
          employeeRepository: FakeEmployeeRepository(
            departments: [
              Department(
                id: 'dept-1',
                name: 'Engineering',
                headEmployeeId: buildTestEmployee().id,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requests Awaiting My Approval'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      expect(requestRepository.lastDecidedRequestId, 'request-1');
    },
  );

  testWidgets(
    'hides the HR approval section from a viewer without users.manage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          requestRepository: FakeRequestRepository(
            pendingHrApproval: [buildTestRequest(id: 'request-hr')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requests Awaiting HR Approval'), findsNothing);
    },
  );

  testWidgets('HR/Admin can approve a request awaiting HR approval', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository(
      pendingHrApproval: [
        buildTestRequest(id: 'request-hr', subject: 'New laptop'),
      ],
    );
    await tester.pumpWidget(
      _app(
        permissions: ['users.manage'],
        requestRepository: requestRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requests Awaiting HR Approval'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(requestRepository.lastDecidedRequestId, 'request-hr');
    expect(requestRepository.lastDecisionApproved, isTrue);
  });

  testWidgets(
    'shows "No need" for manager approval on a profile-change request '
    'awaiting HR',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['users.manage'],
          requestRepository: FakeRequestRepository(
            pendingHrApproval: [
              buildTestRequest(
                id: 'request-pc',
                subject: 'Profile update request',
                kind: 'profile_change',
                status: 'manager_approved',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manager Approval: No need'), findsOneWidget);
      expect(find.textContaining('Approved by manager:'), findsNothing);
    },
  );

  testWidgets(
    'shows who approved as manager on a general request awaiting HR',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['users.manage'],
          requestRepository: FakeRequestRepository(
            pendingHrApproval: [
              buildTestRequest(
                id: 'request-gen',
                subject: 'New laptop',
                status: 'manager_approved',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Approved by manager:'), findsOneWidget);
      expect(find.text('Manager Approval: No need'), findsNothing);
    },
  );

  testWidgets('shows the requester\'s name on a request awaiting approval', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        role: 'Team Lead',
        requestRepository: FakeRequestRepository(
          pendingManagerApproval: [
            buildTestRequest(
              id: 'request-1',
              subject: 'Time off',
              requesterName: 'Babar Hussain',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Babar Hussain'), findsOneWidget);
  });

  testWidgets(
    'shows who rejected a request and why in Request History for HR',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['users.manage'],
          requestRepository: FakeRequestRepository(
            history: [
              buildTestRequest(
                id: 'request-rejected',
                subject: 'Emergency Contact Name change',
                kind: 'profile_change',
                status: 'rejected',
                hrDecisionByName: 'Noushad Ranani',
                hrDecisionAt: DateTime(2026, 9, 2, 14, 0),
                rejectionReason: 'Needs a valid phone number',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request History'), findsOneWidget);
      expect(find.textContaining('Decided by Noushad Ranani'), findsOneWidget);
      expect(
        find.text('Reason: Needs a valid phone number'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows a team-scoped Request History for a manager without users.manage',
    (tester) async {
      await tester.pumpWidget(
        _app(
          role: 'Team Lead',
          requestRepository: FakeRequestRepository(
            historyForMyTeam: [
              buildTestRequest(
                id: 'request-approved',
                subject: 'Time off',
                status: 'completed',
                managerDecisionByName: 'Muhammad Bilal Rathore',
                managerDecisionAt: DateTime(2026, 9, 1),
                hrDecisionByName: 'Noushad Ranani',
                hrDecisionAt: DateTime(2026, 9, 2),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request History'), findsOneWidget);
      expect(find.textContaining('Decided by Noushad Ranani'), findsOneWidget);
    },
  );

  testWidgets(
    'derives a display name from an email for an older decision recorded '
    'before actor-name resolution existed',
    (tester) async {
      await tester.pumpWidget(
        _app(
          permissions: ['users.manage'],
          requestRepository: FakeRequestRepository(
            history: [
              buildTestRequest(
                id: 'request-old',
                status: 'completed',
                hrDecisionByName: 'noushad.ranani@zeracreative.com',
                hrDecisionAt: DateTime(2026, 8, 9),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Decided by Noushad Ranani'), findsOneWidget);
      expect(
        find.textContaining('noushad.ranani@zeracreative.com'),
        findsNothing,
      );
    },
  );

  testWidgets('does not show an avatar in Request History', (tester) async {
    await tester.pumpWidget(
      _app(
        permissions: ['users.manage'],
        requestRepository: FakeRequestRepository(
          history: [
            buildTestRequest(
              id: 'request-1',
              status: 'completed',
              hrDecisionByName: 'Noushad Ranani',
              hrDecisionAt: DateTime(2026, 9, 2),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request History'), findsOneWidget);
    expect(find.byType(EmployeeAvatar), findsNothing);
  });

  testWidgets(
    'hides My Requests and its submission buttons for a Super Admin',
    (tester) async {
      await tester.pumpWidget(
        _app(
          role: 'Super Admin',
          permissions: ['users.manage'],
          requestRepository: FakeRequestRepository(
            pendingHrApproval: [buildTestRequest(id: 'request-hr')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Requests'), findsNothing);
      expect(find.text('New request'), findsNothing);
      // A Super Admin still needs to see and act on everyone else's requests.
      expect(find.text('Requests Awaiting HR Approval'), findsOneWidget);
    },
  );
}
