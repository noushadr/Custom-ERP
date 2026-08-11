import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';
import 'package:zera_erp/features/employee/presentation/pages/employee_directory_page.dart';
import 'package:zera_erp/shared/models/named_ref.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fake_employee.dart';

Future<void> _useNarrowSurface(WidgetTester tester) async {
  // Single-column grid (width < 700) so top-to-bottom position alone
  // reflects sort order — no column arithmetic to account for.
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app({
  required List<String> permissions,
  required FakeEmployeeRepository repository,
}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'HR/Manager',
    permissions: permissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      employeeRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: Scaffold(body: EmployeeDirectoryPage())),
  );
}

void main() {
  testWidgets('shows the employee list and invite button with full access', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.read', 'employees.manage'],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsOneWidget);
  });

  testWidgets('hides the invite button without employees.manage', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Invite Employee'), findsNothing);
  });

  testWidgets('shows the manage departments button with departments.manage', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(
        permissions: ['employees.read', 'departments.manage'],
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage Departments'), findsOneWidget);
  });

  testWidgets('hides the manage departments button without departments.manage', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage Departments'), findsNothing);
  });

  testWidgets('hierarchy view nests reports under their manager', (
    tester,
  ) async {
    final manager = buildTestEmployee(
      id: 'manager-1',
      fullName: 'Mona Manager',
      designation: 'Engineering Lead',
    );
    final report = buildTestEmployee(
      id: 'report-1',
      fullName: 'Ravi Report',
      designation: 'Software Engineer',
      reportingManager: const NamedRef(id: 'manager-1', name: 'Mona Manager'),
    );
    final repository = FakeEmployeeRepository(employees: [manager, report]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    // Default view is the flat list.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.tap(find.text('Hierarchy'));
    await tester.pumpAndSettle();

    // Nodes start collapsed until the user opens them.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsNothing);
    expect(find.textContaining('1 person'), findsOneWidget);

    await tester.tap(find.textContaining('1 person'));
    await tester.pumpAndSettle();

    // The report is nested under the manager, not shown as a root.
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);
  });

  testWidgets('filters the list by search query', (tester) async {
    final jane = buildTestEmployee(id: 'employee-1', fullName: 'Jane Doe');
    final ravi = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Ravi Report',
      email: 'ravi.report@zeracreative.com',
      designation: 'Software Engineer',
    );
    final repository = FakeEmployeeRepository(employees: [jane, ravi]);

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ravi');
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsNothing);
    expect(find.text('Ravi Report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nobody matches this');
    await tester.pumpAndSettle();

    expect(find.text('No employees match your search.'), findsOneWidget);
  });

  testWidgets('shows each employee\'s department and reporting manager', (
    tester,
  ) async {
    final withBoth = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Jane Doe',
      department: const NamedRef(id: 'dept-eng', name: 'Engineering'),
      reportingManager: const NamedRef(id: 'employee-2', name: 'Mona Manager'),
    );
    final withNeither = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Mona Manager',
      email: 'mona.manager@zeracreative.com',
    );
    final repository = FakeEmployeeRepository(
      employees: [withBoth, withNeither],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Mona Manager'), findsOneWidget);
    expect(find.text('Reports to: Mona Manager'), findsOneWidget);
    expect(find.text('No department'), findsOneWidget);
    expect(find.text('Reports to: —'), findsOneWidget);
  });

  testWidgets('shows a restricted message without employees.read', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(
      employees: [buildTestEmployee()],
    );

    await tester.pumpWidget(_app(permissions: [], repository: repository));
    await tester.pumpAndSettle();

    expect(
      find.text("You don't have access to the full directory."),
      findsOneWidget,
    );
    expect(find.text('View my profile'), findsOneWidget);
  });

  testWidgets('sorts by joining date, earliest first', (tester) async {
    await _useNarrowSurface(tester);
    final newest = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Newest Hire',
      joiningDate: '2026-06-01',
    );
    final oldest = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Oldest Hire',
      email: 'oldest.hire@zeracreative.com',
      joiningDate: '2020-01-15',
    );
    final middle = buildTestEmployee(
      id: 'employee-3',
      fullName: 'Middle Hire',
      email: 'middle.hire@zeracreative.com',
      joiningDate: '2023-03-10',
    );
    final repository = FakeEmployeeRepository(
      employees: [newest, oldest, middle],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joining date'));
    await tester.pumpAndSettle();

    final oldestY = tester.getTopLeft(find.text('Oldest Hire')).dy;
    final middleY = tester.getTopLeft(find.text('Middle Hire')).dy;
    final newestY = tester.getTopLeft(find.text('Newest Hire')).dy;
    expect(oldestY, lessThan(middleY));
    expect(middleY, lessThan(newestY));
  });

  testWidgets('sorts by company ID', (tester) async {
    await _useNarrowSurface(tester);
    final third = buildTestEmployee(
      id: 'employee-1',
      fullName: 'Employee C',
      employeeCode: 'ZC-00003',
    );
    final first = buildTestEmployee(
      id: 'employee-2',
      fullName: 'Employee A',
      email: 'employee.a@zeracreative.com',
      employeeCode: 'ZC-00001',
    );
    final second = buildTestEmployee(
      id: 'employee-3',
      fullName: 'Employee B',
      email: 'employee.b@zeracreative.com',
      employeeCode: 'ZC-00002',
    );
    final repository = FakeEmployeeRepository(
      employees: [third, first, second],
    );

    await tester.pumpWidget(
      _app(permissions: ['employees.read'], repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company ID'));
    await tester.pumpAndSettle();

    final firstY = tester.getTopLeft(find.text('Employee A')).dy;
    final secondY = tester.getTopLeft(find.text('Employee B')).dy;
    final thirdY = tester.getTopLeft(find.text('Employee C')).dy;
    expect(firstY, lessThan(secondY));
    expect(secondY, lessThan(thirdY));
  });

  testWidgets(
    'sorts by department alphabetically, with unassigned employees last',
    (tester) async {
      await _useNarrowSurface(tester);
      final unassigned = buildTestEmployee(
        id: 'employee-1',
        fullName: 'No Department',
      );
      final sales = buildTestEmployee(
        id: 'employee-2',
        fullName: 'Sales Person',
        email: 'sales.person@zeracreative.com',
        department: const NamedRef(id: 'dept-sales', name: 'Sales'),
      );
      final engineering = buildTestEmployee(
        id: 'employee-3',
        fullName: 'Engineering Person',
        email: 'engineering.person@zeracreative.com',
        department: const NamedRef(id: 'dept-eng', name: 'Engineering'),
      );
      final repository = FakeEmployeeRepository(
        employees: [unassigned, sales, engineering],
      );

      await tester.pumpWidget(
        _app(permissions: ['employees.read'], repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Department'));
      await tester.pumpAndSettle();

      final engineeringY = tester.getTopLeft(find.text('Engineering Person')).dy;
      final salesY = tester.getTopLeft(find.text('Sales Person')).dy;
      final unassignedY = tester.getTopLeft(find.text('No Department')).dy;
      expect(engineeringY, lessThan(salesY));
      expect(salesY, lessThan(unassignedY));
    },
  );
}
