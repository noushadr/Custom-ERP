import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/notices/application/notice_providers.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_employee.dart';
import 'helpers/fake_notice.dart';
import 'helpers/fake_request.dart';

Widget _authenticatedApp({AuthUser user = testAuthUser}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(employees: [buildTestEmployee()]),
      ),
      noticeRepositoryProvider.overrideWithValue(FakeNoticeRepository()),
      requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
    ],
    child: const ZeraApp(),
  );
}

void main() {
  testWidgets('renders the user dashboard by default for a plain employee', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('Company Notices'), findsOneWidget);
    expect(find.text('Team Members'), findsOneWidget);
  });

  testWidgets('renders the admin dashboard stats for a Super Admin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _authenticatedApp(
        user: const AuthUser(
          id: 'admin-1',
          email: 'admin@zeracreative.com',
          role: 'Super Admin',
          permissions: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Employees'), findsOneWidget);
    expect(find.text('Employment Status'), findsOneWidget);
  });

  testWidgets('switching destinations updates the body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);
  });

  testWidgets(
    'hides Employees and Settings from the nav for a plain employee',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('Employees'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );

  testWidgets(
    'shows Employees and Settings in the nav for a Super Admin',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employees'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'a Super Admin sees only Admin Dashboard, never User Dashboard',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _authenticatedApp(
          user: const AuthUser(
            id: 'admin-1',
            email: 'admin@zeracreative.com',
            role: 'Super Admin',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsWidgets);
      expect(find.text('User Dashboard'), findsNothing);
      expect(find.text('Total Employees'), findsOneWidget);
    },
  );

  testWidgets(
    'a plain employee sees only User Dashboard, never Admin Dashboard',
    (WidgetTester tester) async {
      await tester.pumpWidget(_authenticatedApp());
      await tester.pumpAndSettle();

      expect(find.text('User Dashboard'), findsWidgets);
      expect(find.text('Admin Dashboard'), findsNothing);
      expect(find.text('Total Employees'), findsNothing);
    },
  );
}
