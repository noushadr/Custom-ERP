import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/role_providers.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role.dart';
import '../../domain/exceptions/auth_exception.dart';

/// Lets Super Admin define custom roles and toggle which permissions each
/// role grants — the four built-in roles (Super Admin, HR/Manager, Team
/// Lead, Employee) can have their permissions edited but not be renamed or
/// deleted. Requires `roles.manage`.
class RolePermissionsPage extends ConsumerWidget {
  const RolePermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
        actions: [
          IconButton(
            tooltip: 'Add role',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _RoleFormDialog(role: null),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: rolesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(
              child: Text('Could not load roles. Please try again.'),
            ),
            data: (roles) => ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: roles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RoleCard(role: roles[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  const _RoleCard({required this.role});

  final Role role;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'This permanently deletes "${role.name}". It fails if any '
          'employees still have this role — reassign them first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(roleRepositoryProvider).deleteRole(role.id);
      ref.invalidate(rolesProvider);
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      role.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (role.isSystem) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'System',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((role.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    role.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  role.userCount == 1
                      ? '1 employee'
                      : '${role.userCount} employees',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final permission in role.permissions)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          permission,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    if (role.permissions.isEmpty)
                      Text(
                        'No permissions granted',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _RoleFormDialog(role: role),
            ),
          ),
          if (!role.isSystem)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }
}

class _RoleFormDialog extends ConsumerStatefulWidget {
  const _RoleFormDialog({required this.role});

  final Role? role;

  @override
  ConsumerState<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends ConsumerState<_RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Set<String> _selectedKeys;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.role != null;
  bool get _isSystem => widget.role?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name);
    _descriptionController = TextEditingController(
      text: widget.role?.description,
    );
    _selectedKeys = {...?widget.role?.permissions};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(roleRepositoryProvider);
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      if (_isEditing) {
        await repository.updateRole(
          widget.role!.id,
          name: _isSystem ? null : name,
          description: description,
          permissionKeys: _selectedKeys.toList(),
        );
      } else {
        await repository.createRole(
          name: name,
          description: description,
          permissionKeys: _selectedKeys.toList(),
        );
      }
      ref.invalidate(rolesProvider);
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(permissionsProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit role' : 'Add role'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                enabled: !_saving && !_isSystem,
                decoration: InputDecoration(
                  labelText: 'Name',
                  helperText: _isSystem
                      ? "System roles can't be renamed"
                      : null,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Permissions',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: permissionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not load permissions.'),
                  data: (permissions) => _PermissionCheckboxList(
                    permissions: permissions,
                    selectedKeys: _selectedKeys,
                    enabled: !_saving,
                    onChanged: (keys) => setState(() => _selectedKeys = keys),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save changes' : 'Add role'),
        ),
      ],
    );
  }
}

class _PermissionCheckboxList extends StatelessWidget {
  const _PermissionCheckboxList({
    required this.permissions,
    required this.selectedKeys,
    required this.enabled,
    required this.onChanged,
  });

  final List<Permission> permissions;
  final Set<String> selectedKeys;
  final bool enabled;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final permission in permissions)
          CheckboxListTile(
            key: Key('permission-${permission.key}'),
            value: selectedKeys.contains(permission.key),
            onChanged: !enabled
                ? null
                : (checked) {
                    final next = {...selectedKeys};
                    if (checked ?? false) {
                      next.add(permission.key);
                    } else {
                      next.remove(permission.key);
                    }
                    onChanged(next);
                  },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(permission.key),
            subtitle: (permission.description ?? '').isEmpty
                ? null
                : Text(permission.description!),
          ),
      ],
    );
  }
}
