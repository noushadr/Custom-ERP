import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/edit_employee_page.dart';

import '../../helpers/fake_employee.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('pre-fills existing values and saves changes', (tester) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Other Person',
    );
    final updated = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Other Person',
    );
    final repository = FakeEmployeeRepository(
      employees: [employee],
      updateEmployeeResult: updated,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: EditEmployeePage(employee: employee)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Other Person'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'First name'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Designation'),
      'Senior Engineer',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // Successful save pops back to the page that opened the editor.
    expect(find.text('Edit Other Person'), findsNothing);
  });

  testWidgets('shows an error snackbar when saving fails', (tester) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee(id: 'employee-2');
    final repository = FakeEmployeeRepository(
      employees: [employee],
      updateEmployeeError: const EmployeeException('Something went wrong.'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: EditEmployeePage(employee: employee)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('rejects an empty first name', (tester) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee(id: 'employee-2');
    final repository = FakeEmployeeRepository(employees: [employee]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: EditEmployeePage(employee: employee)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      '',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('First name is required'), findsOneWidget);
  });
}
