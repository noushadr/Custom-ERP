import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/department.dart';
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

  testWidgets('submitting an item request calls the repository', (
    tester,
  ) async {
    final requestRepository = FakeRequestRepository();
    await tester.pumpWidget(_app(requestRepository: requestRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request an item'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item needed'),
      'Stapler',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purpose'),
      'Mine broke.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(requestRepository.lastItemName, 'Stapler');
    expect(requestRepository.lastItemPurpose, 'Mine broke.');
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
      expect(find.text('Request an item'), findsNothing);
      // A Super Admin still needs to see and act on everyone else's requests.
      expect(find.text('Requests Awaiting HR Approval'), findsOneWidget);
    },
  );
}
