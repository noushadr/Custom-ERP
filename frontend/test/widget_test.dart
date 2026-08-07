import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_employee.dart';

Widget _authenticatedApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        FakeEmployeeRepository(employees: [buildTestEmployee()]),
      ),
    ],
    child: const ZeraApp(),
  );
}

void main() {
  testWidgets('renders the dashboard stats by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.text('Total Employees'), findsOneWidget);
    expect(find.text('Employment Status'), findsOneWidget);
  });

  testWidgets('switching destinations updates the body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings — coming soon'), findsOneWidget);
  });
}
