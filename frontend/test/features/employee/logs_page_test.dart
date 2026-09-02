import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/domain/entities/audit_log_entry.dart';
import 'package:zera_erp/features/employee/presentation/pages/logs_page.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Widget _app({FakeEmployeeRepository? repository, AuthUser? viewer}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(viewer ?? _admin)),
      ),
      employeeRepositoryProvider.overrideWithValue(
        repository ?? FakeEmployeeRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: LogsPage())),
  );
}

const _admin = AuthUser(
  id: 'admin-1',
  email: 'admin@zeracreative.com',
  role: 'Super Admin',
  permissions: ['audit.viewAll'],
);

void main() {
  testWidgets('shows the company-wide change log for a viewer with '
      'audit.viewAll', (tester) async {
    final repository = FakeEmployeeRepository(
      auditLog: [
        AuditLogEntry(
          id: 'log-1',
          employeeName: 'Jane Doe',
          actorName: 'Admin User',
          fieldLabel: 'Designation',
          oldValue: 'Engineer',
          newValue: 'Senior Engineer',
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
    );

    await tester.pumpWidget(_app(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Company-wide Changes'), findsOneWidget);
    expect(find.textContaining('Jane Doe'), findsOneWidget);
  });

  testWidgets(
    'shows the viewer\'s own change history for a viewer without '
    'audit.viewAll, not the company-wide section or an access-denied '
    'message',
    (tester) async {
      final repository = FakeEmployeeRepository(
        auditLog: [
          AuditLogEntry(
            id: 'log-1',
            employeeName: 'Employee User',
            actorName: 'Admin User',
            fieldLabel: 'Designation',
            oldValue: 'Engineer',
            newValue: 'Senior Engineer',
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          repository: repository,
          viewer: const AuthUser(
            id: 'employee-1',
            email: 'employee@zeracreative.com',
            role: 'Employee',
            permissions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change History'), findsOneWidget);
      expect(find.text('Designation'), findsOneWidget);
      expect(find.text('Company-wide Changes'), findsNothing);
      expect(
        find.text("You don't have permission to view this page."),
        findsNothing,
      );
    },
  );
}
