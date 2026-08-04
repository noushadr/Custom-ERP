import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/exceptions/employee_exception.dart';
import 'package:zera_erp/features/employee/presentation/pages/edit_my_profile_page.dart';

import '../../helpers/fake_employee.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('pre-fills existing values and saves changes', (tester) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee();
    final updated = buildTestEmployee();
    final repository = FakeEmployeeRepository(
      me: employee,
      updateMeResult: updated,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditMyProfilePage(employee: employee),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Edit My Profile'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '+15551234567',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // Successful save pops back to the page that opened the editor.
    expect(find.text('Edit My Profile'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('shows an error snackbar when saving fails', (tester) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee();
    final repository = FakeEmployeeRepository(
      me: employee,
      updateMeError: const EmployeeException('Something went wrong.'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: EditMyProfilePage(employee: employee)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Edit My Profile'), findsOneWidget);
  });
}
