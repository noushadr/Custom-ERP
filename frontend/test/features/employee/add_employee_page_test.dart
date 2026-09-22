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

/// The new Password field pushed the "Add" button below the default
/// 800x600 test surface.
Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Company email'),
    'new.hire@zeracreative.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'Sup3rSecret',
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
    await _useTallSurface(tester);
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Company email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
  });

  testWidgets('rejects a password shorter than 8 characters', (tester) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Must be at least 8 characters'), findsOneWidget);
  });

  testWidgets(
    'accepts any local part, not just firstname.lastname, as long as the '
    'domain is @zeracreative.com',
    (tester) async {
      await _useTallSurface(tester);
      final repository = FakeEmployeeRepository(
        addEmployeeResult: buildTestEmployee(fullName: 'New Hire'),
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Company email'),
        'newhire123@zeracreative.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Sup3rSecret',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'New',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last name'),
        'Hire',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('New Hire has been added.'), findsOneWidget);
    },
  );

  testWidgets('rejects an email whose domain is not @zeracreative.com', (
    tester,
  ) async {
    await _useTallSurface(tester);
    await tester.pumpWidget(_app(FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company email'),
      'someone@example.com',
    );
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Must be a @zeracreative.com address'), findsOneWidget);
  });

  testWidgets(
    'pre-fills the company email field with the @zeracreative.com domain',
    (tester) async {
      await tester.pumpWidget(_app(FakeEmployeeRepository()));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Company email'),
      );
      expect(field.controller?.text, '@zeracreative.com');
    },
  );

  testWidgets('shows a success message with the employee name', (tester) async {
    await _useTallSurface(tester);
    final repository = FakeEmployeeRepository(
      addEmployeeResult: buildTestEmployee(fullName: 'New Hire'),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _fillRequiredFields(tester);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New Hire has been added.'), findsOneWidget);
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
    await _useTallSurface(tester);
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

    expect(find.text('A user with this email already exists.'), findsOneWidget);
  });
}
