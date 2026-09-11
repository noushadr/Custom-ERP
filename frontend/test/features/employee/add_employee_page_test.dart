import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/add_employee_page.dart';

import '../../helpers/fake_employee.dart';

Widget _app(FakeEmployeeRepository repository) {
  return ProviderScope(
    overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: AddEmployeePage()),
  );
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Company email'),
    'new.hire@zeracreative.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'First name'),
    'New',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Last name'),
    'Hire',
  );
}

void main() {
  testWidgets('shows validation errors for empty required fields', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Company email is required'), findsOneWidget);
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
  });

  testWidgets('rejects an email that does not match the company format', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company email'),
      'not-the-right-format@zeracreative.com',
    );
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(
      find.text('Must match firstname.lastname@zeracreative.com'),
      findsOneWidget,
    );
  });

  testWidgets('shows the temporary password on success', (tester) async {
    final repository = FakeEmployeeRepository(
      addEmployeeResult: (
        employee: buildTestEmployee(fullName: 'New Hire'),
        temporaryPassword: 'Sup3rSecret',
      ),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New Hire has been added.'), findsOneWidget);
    expect(find.text('Sup3rSecret'), findsOneWidget);
  });

  testWidgets('defaults the work mode dropdown to On-site', (tester) async {
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.widgetWithText(DropdownButtonFormField<String>, 'Work mode'),
        matching: find.text('On-site'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows an error message when adding the employee fails', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      addEmployeeError: const EmployeeException(
        'A user with this email already exists.',
      ),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(
      find.text('A user with this email already exists.'),
      findsOneWidget,
    );
  });
}
