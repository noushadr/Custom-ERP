import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_profile_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({
  required AuthUser viewer,
  required FakeEmployeeRepository repository,
  String? employeeId,
  FakeAuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(
          AuthAuthenticated(viewer),
          repository: authRepository,
        ),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(home: EmployeeProfilePage(employeeId: employeeId)),
  );
}

void main() {
  testWidgets('shows Edit for your own profile and opens the self-service form', (
    tester,
  ) async {
    final me = buildTestEmployee(email: 'jane.doe@zeracreative.com');
    final viewer = AuthUser(
      id: 'user-1',
      email: 'jane.doe@zeracreative.com',
      role: 'Employee',
      permissions: const [],
    );

    await tester.pumpWidget(
      _app(viewer: viewer, repository: FakeEmployeeRepository(me: me)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit My Profile'), findsOneWidget);
  });

  testWidgets(
    'shows Edit for someone else\'s profile when the viewer can manage employees',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'employees.manage'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Other Person'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Edit for someone else\'s profile when the viewer cannot manage employees',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'user-3',
        email: 'coworker@zeracreative.com',
        role: 'Employee',
        permissions: const ['employees.read'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
    },
  );

  testWidgets(
    'shows "Login as" for a Super Admin viewing someone else\'s profile',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        userId: 'user-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'admin-1',
        email: 'admin@zeracreative.com',
        role: 'Super Admin',
        permissions: const ['employees.read', 'users.impersonate'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login as'), findsOneWidget);
    },
  );

  testWidgets(
    'hides "Login as" without the users.impersonate permission',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        userId: 'user-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'employees.manage'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login as'), findsNothing);
    },
  );

  testWidgets('hides "Login as" on your own profile', (tester) async {
    final me = buildTestEmployee(
      userId: 'admin-1',
      email: 'admin@zeracreative.com',
    );
    final viewer = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: const ['employees.read', 'users.impersonate'],
    );

    await tester.pumpWidget(
      _app(viewer: viewer, repository: FakeEmployeeRepository(me: me)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login as'), findsNothing);
  });

  testWidgets('tapping "Login as" impersonates that employee\'s user', (
    tester,
  ) async {
    final other = buildTestEmployee(
      id: 'employee-2',
      userId: 'user-2',
      email: 'other.person@zeracreative.com',
      fullName: 'Other Person',
    );
    final viewer = AuthUser(
      id: 'admin-1',
      email: 'admin@zeracreative.com',
      role: 'Super Admin',
      permissions: const ['employees.read', 'users.impersonate'],
    );
    final authRepository = FakeAuthRepository(
      impersonateResult: AuthUser(
        id: 'user-2',
        email: 'other.person@zeracreative.com',
        role: 'Employee',
        permissions: const [],
      ),
    );

    await tester.pumpWidget(
      _app(
        viewer: viewer,
        employeeId: 'employee-2',
        repository: FakeEmployeeRepository(employees: [other]),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login as'));
    await tester.pumpAndSettle();

    expect(authRepository.lastImpersonatedUserId, 'user-2');
  });

  testWidgets(
    'shows "Reset password" for a viewer with users.manage',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'users.manage'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsOneWidget);
    },
  );

  testWidgets(
    'hides "Reset password" without users.manage',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'user-3',
        email: 'coworker@zeracreative.com',
        role: 'Employee',
        permissions: const ['employees.read'],
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsNothing);
    },
  );

  testWidgets(
    'confirming "Reset password" shows the new temporary password',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        userId: 'user-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'users.manage'],
      );
      final authRepository = FakeAuthRepository(
        resetPasswordResult: 'Nx7kP2qRstuv',
      );

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
          authRepository: authRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      // Confirmation dialog first — the request hasn't gone out yet.
      expect(find.text('Reset password?'), findsOneWidget);
      expect(authRepository.lastResetPasswordUserId, isNull);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Reset password'),
      );
      await tester.pumpAndSettle();

      expect(authRepository.lastResetPasswordUserId, 'user-2');
      expect(find.text('Nx7kP2qRstuv'), findsOneWidget);
    },
  );

  testWidgets(
    'canceling the confirmation does not reset the password',
    (tester) async {
      final other = buildTestEmployee(
        id: 'employee-2',
        userId: 'user-2',
        email: 'other.person@zeracreative.com',
        fullName: 'Other Person',
      );
      final viewer = AuthUser(
        id: 'hr-1',
        email: 'hr.manager@zeracreative.com',
        role: 'HR/Manager',
        permissions: const ['employees.read', 'users.manage'],
      );
      final authRepository = FakeAuthRepository();

      await tester.pumpWidget(
        _app(
          viewer: viewer,
          employeeId: 'employee-2',
          repository: FakeEmployeeRepository(employees: [other]),
          authRepository: authRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(authRepository.lastResetPasswordUserId, isNull);
    },
  );
}
