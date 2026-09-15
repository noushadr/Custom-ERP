import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/authentication/domain/entities/auth_user.dart';
import 'package:zera_erp/features/authentication/domain/entities/permission.dart';
import 'package:zera_erp/features/authentication/domain/entities/role.dart';
import 'package:zera_erp/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:zera_erp/features/authentication/domain/repositories/role_repository.dart';
import 'package:zera_erp/features/authentication/application/role_providers.dart';
import 'package:zera_erp/features/authentication/presentation/pages/role_permissions_page.dart';

import '../../helpers/fake_auth.dart';

class FakeRoleRepository implements RoleRepository {
  FakeRoleRepository({
    this.roles = const [],
    this.permissions = const [],
    this.createResult,
    this.createError,
    this.updateResult,
    this.updateError,
    this.deleteError,
  });

  final List<Role> roles;
  final List<Permission> permissions;
  final Role? createResult;
  final Object? createError;
  final Role? updateResult;
  final Object? updateError;
  final Object? deleteError;

  ({String name, String? description, List<String> permissionKeys})?
  lastCreateInput;
  ({
    String id,
    String? name,
    String? description,
    List<String>? permissionKeys,
  })?
  lastUpdateInput;
  String? lastDeleteId;

  @override
  Future<List<Role>> getRoles() async => roles;

  @override
  Future<List<Permission>> getPermissions() async => permissions;

  @override
  Future<Role> createRole({
    required String name,
    String? description,
    required List<String> permissionKeys,
  }) async {
    lastCreateInput = (
      name: name,
      description: description,
      permissionKeys: permissionKeys,
    );
    if (createError != null) throw createError!;
    return createResult ??
        Role(
          id: 'role-new',
          name: name,
          description: description,
          isSystem: false,
          permissions: permissionKeys,
          userCount: 0,
        );
  }

  @override
  Future<Role> updateRole(
    String id, {
    String? name,
    String? description,
    List<String>? permissionKeys,
  }) async {
    lastUpdateInput = (
      id: id,
      name: name,
      description: description,
      permissionKeys: permissionKeys,
    );
    if (updateError != null) throw updateError!;
    return updateResult ??
        Role(
          id: id,
          name: name ?? 'Role',
          description: description,
          isSystem: false,
          permissions: permissionKeys ?? const [],
          userCount: 0,
        );
  }

  @override
  Future<void> deleteRole(String id) async {
    lastDeleteId = id;
    if (deleteError != null) throw deleteError!;
  }
}

Widget _app(
  FakeRoleRepository repository, {
  List<String> viewerPermissions = const [
    'roles.manage',
    'employees.read',
    'employees.manage',
  ],
}) {
  final user = AuthUser(
    id: 'user-1',
    email: 'jane.doe@zeracreative.com',
    role: 'Super Admin',
    permissions: viewerPermissions,
  );

  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(AuthAuthenticated(user)),
      ),
      roleRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: RolePermissionsPage()),
  );
}

void main() {
  testWidgets('shows roles with their permissions and a System badge', (
    tester,
  ) async {
    final repository = FakeRoleRepository(
      roles: const [
        Role(
          id: 'role-1',
          name: 'Super Admin',
          isSystem: true,
          permissions: ['users.manage'],
          userCount: 1,
        ),
        Role(
          id: 'role-2',
          name: 'Project Coordinator',
          description: 'Coordinates cross-team projects',
          isSystem: false,
          permissions: [],
          userCount: 0,
        ),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Super Admin'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('users.manage'), findsOneWidget);
    expect(find.text('Project Coordinator'), findsOneWidget);
    expect(find.text('Coordinates cross-team projects'), findsOneWidget);
    expect(find.text('No permissions granted'), findsOneWidget);
  });

  testWidgets('hides the delete action for a system role', (tester) async {
    final repository = FakeRoleRepository(
      roles: const [
        Role(
          id: 'role-1',
          name: 'Super Admin',
          isSystem: true,
          permissions: [],
          userCount: 1,
        ),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('creating a role sends the name and checked permissions', (
    tester,
  ) async {
    final repository = FakeRoleRepository(
      permissions: const [
        Permission(key: 'employees.read'),
        Permission(key: 'employees.manage'),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Project Coordinator',
    );
    await tester.tap(find.byKey(const Key('permission-employees.read')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add role').last);
    await tester.pumpAndSettle();

    expect(repository.lastCreateInput?.name, 'Project Coordinator');
    expect(repository.lastCreateInput?.permissionKeys, ['employees.read']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("disables the name field when editing a system role", (
    tester,
  ) async {
    final repository = FakeRoleRepository(
      roles: const [
        Role(
          id: 'role-1',
          name: 'HR/Manager',
          isSystem: true,
          permissions: ['employees.manage'],
          userCount: 2,
        ),
      ],
      permissions: const [Permission(key: 'employees.manage')],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Name'),
    );
    expect(nameField.enabled, isFalse);
    expect(
      find.text("System roles can't be renamed"),
      findsOneWidget,
    );
  });

  testWidgets('deleting a role asks for confirmation before calling deleteRole', (
    tester,
  ) async {
    final repository = FakeRoleRepository(
      roles: const [
        Role(
          id: 'role-2',
          name: 'Project Coordinator',
          isSystem: false,
          permissions: [],
          userCount: 0,
        ),
      ],
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete role?'), findsOneWidget);
    expect(repository.lastDeleteId, isNull);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.lastDeleteId, 'role-2');
  });

  testWidgets(
    'shows the conflict message when a role still has employees assigned',
    (tester) async {
      final repository = FakeRoleRepository(
        roles: const [
          Role(
            id: 'role-2',
            name: 'Project Coordinator',
            isSystem: false,
            permissions: [],
            userCount: 3,
          ),
        ],
        deleteError: const AuthException(
          'Cannot delete a role with 3 employee(s) assigned. Reassign them '
          'first.',
        ),
      );

      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cannot delete a role with 3 employee(s) assigned. Reassign them '
          'first.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'disables editing the Super Admin role for a viewer missing any '
    'permission',
    (tester) async {
      final repository = FakeRoleRepository(
        roles: const [
          Role(
            id: 'role-super-admin',
            name: 'Super Admin',
            isSystem: true,
            permissions: ['a', 'b'],
            userCount: 1,
          ),
        ],
        permissions: const [Permission(key: 'a'), Permission(key: 'b')],
      );

      await tester.pumpWidget(
        _app(repository, viewerPermissions: const ['roles.manage', 'a']),
      );
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('Only a Super Admin can edit the Super Admin role'),
        findsOneWidget,
      );
      final editButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.edit_outlined),
      );
      expect(editButton.onPressed, isNull);
    },
  );

  testWidgets(
    'allows editing the Super Admin role for a viewer holding every '
    'permission',
    (tester) async {
      final repository = FakeRoleRepository(
        roles: const [
          Role(
            id: 'role-super-admin',
            name: 'Super Admin',
            isSystem: true,
            permissions: ['a', 'b'],
            userCount: 1,
          ),
        ],
        permissions: const [Permission(key: 'a'), Permission(key: 'b')],
      );

      await tester.pumpWidget(
        _app(
          repository,
          viewerPermissions: const ['roles.manage', 'a', 'b'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit role'), findsOneWidget);
    },
  );

  testWidgets(
    'disables newly granting a permission the viewer does not hold, but '
    'still allows removing one the role already had',
    (tester) async {
      final repository = FakeRoleRepository(
        roles: const [
          Role(
            id: 'role-team-lead',
            name: 'Team Lead',
            isSystem: true,
            permissions: ['a'],
            userCount: 1,
          ),
        ],
        permissions: const [Permission(key: 'a'), Permission(key: 'b')],
      );

      // Viewer holds 'a' (already on the role) but not 'b'.
      await tester.pumpWidget(
        _app(repository, viewerPermissions: const ['roles.manage', 'a']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      final checkboxA = tester.widget<CheckboxListTile>(
        find.byKey(const Key('permission-a')),
      );
      final checkboxB = tester.widget<CheckboxListTile>(
        find.byKey(const Key('permission-b')),
      );
      // 'a' was already granted — can still be unchecked despite the
      // viewer not holding... wait, viewer DOES hold 'a' here; the point is
      // it stays toggleable either way.
      expect(checkboxA.onChanged, isNotNull);
      // 'b' isn't on the role yet and the viewer doesn't hold it — can't be
      // newly checked.
      expect(checkboxB.onChanged, isNull);
      expect(
        find.byTooltip("You don't hold this permission, so you can't grant it."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "allows unchecking a permission the role already had even though the "
    'viewer does not hold it themselves',
    (tester) async {
      final repository = FakeRoleRepository(
        roles: const [
          Role(
            id: 'role-team-lead',
            name: 'Team Lead',
            isSystem: true,
            permissions: ['b'],
            userCount: 1,
          ),
        ],
        permissions: const [Permission(key: 'a'), Permission(key: 'b')],
      );

      // Viewer holds neither 'a' nor 'b' themselves, but 'b' is already on
      // the role.
      await tester.pumpWidget(
        _app(repository, viewerPermissions: const ['roles.manage']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      final checkboxB = tester.widget<CheckboxListTile>(
        find.byKey(const Key('permission-b')),
      );
      expect(checkboxB.onChanged, isNotNull);

      await tester.tap(find.byKey(const Key('permission-b')));
      await tester.tap(find.text('Save changes').last);
      await tester.pumpAndSettle();

      expect(repository.lastUpdateInput?.permissionKeys, <String>[]);
    },
  );
}
