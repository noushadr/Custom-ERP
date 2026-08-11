import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/edit_my_profile_page.dart';
import 'package:zera_erp/features/requests/application/request_providers.dart';
import 'package:zera_erp/features/requests/domain/exceptions/request_exception.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';
import '../../helpers/fake_request.dart';

Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'pre-fills existing values and submits a profile-change request',
    (tester) async {
      await _useTallSurface(tester);
      final employee = buildTestEmployee();
      final requestRepository = FakeRequestRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => PresetAuthController(AuthAuthenticated(testAuthUser)),
            ),
            employeeRepositoryProvider.overrideWithValue(
              FakeEmployeeRepository(me: employee),
            ),
            requestRepositoryProvider.overrideWithValue(requestRepository),
          ],
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
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      // Submitting pops back to the page that opened the editor — the
      // profile itself isn't touched until HR/Admin approves.
      expect(find.text('Edit My Profile'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(requestRepository.lastProfileChanges?['phoneNumber'], '+15551234567');
    },
  );

  testWidgets('shows an error snackbar when submitting fails', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final employee = buildTestEmployee();
    final requestRepository = FakeRequestRepository(
      submitError: const RequestException('Something went wrong.'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => PresetAuthController(AuthAuthenticated(testAuthUser)),
          ),
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(me: employee),
          ),
          requestRepositoryProvider.overrideWithValue(requestRepository),
        ],
        child: MaterialApp(home: EditMyProfilePage(employee: employee)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Edit My Profile'), findsOneWidget);
  });

  testWidgets(
    'a Super Admin saves changes immediately instead of requesting approval',
    (tester) async {
      await _useTallSurface(tester);
      final employee = buildTestEmployee();
      final employeeRepository = FakeEmployeeRepository(me: employee);
      final requestRepository = FakeRequestRepository();
      const superAdmin = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => PresetAuthController(AuthAuthenticated(superAdmin)),
            ),
            employeeRepositoryProvider.overrideWithValue(employeeRepository),
            requestRepositoryProvider.overrideWithValue(requestRepository),
          ],
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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'),
        '+15551234567',
      );
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit My Profile'), findsNothing);
      expect(
        employeeRepository.lastUpdateMeInput?.phoneNumber,
        '+15551234567',
      );
      expect(requestRepository.lastProfileChanges, isNull);
      expect(find.text('Profile updated.'), findsOneWidget);
    },
  );
}
