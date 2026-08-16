import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_status_badges.dart';

/// Refetches both the archived and non-archived department lists — since
/// [departmentsManagementProvider] is keyed by that bool, invalidating the
/// bare family reference isn't guaranteed to refresh whichever instance is
/// currently on screen, so both are named explicitly.
void _invalidateDepartments(WidgetRef ref) {
  ref.invalidate(departmentsManagementProvider(true));
  ref.invalidate(departmentsManagementProvider(false));
  ref.invalidate(departmentsProvider);
}

/// Lets Super Admin/HR-Manager view, create, edit, archive, and delete
/// departments. Requires `departments.manage`.
class DepartmentsPage extends ConsumerStatefulWidget {
  const DepartmentsPage({super.key});

  @override
  ConsumerState<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends ConsumerState<DepartmentsPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(
      departmentsManagementProvider(_includeArchived),
    );
    final employeesAsync = ref.watch(employeeListProvider);
    final employees = employeesAsync.valueOrNull ?? const [];
    final employeesById = {for (final employee in employees) employee.id: employee};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments'),
        actions: [
          IconButton(
            tooltip: 'Add department',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _DepartmentFormDialog(department: null),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Show archived',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Switch(
                      value: _includeArchived,
                      onChanged: (value) =>
                          setState(() => _includeArchived = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: departmentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Could not load departments. Please try again.'),
                  ),
                  data: (departments) {
                    if (departments.isEmpty) {
                      return Center(
                        child: Text(
                          _includeArchived
                              ? 'No departments yet.'
                              : 'No active departments. Turn on "Show archived" to see archived ones.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: departments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final department = departments[index];
                        final headEmployee =
                            employeesById[department.headEmployeeId];
                        final members = employees
                            .where((e) => e.department?.id == department.id)
                            .toList();
                        return _DepartmentCard(
                          department: department,
                          headEmployee: headEmployee,
                          members: members,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends ConsumerWidget {
  const _DepartmentCard({
    required this.department,
    required this.headEmployee,
    required this.members,
  });

  final Department department;
  final Employee? headEmployee;
  final List<Employee> members;

  Future<void> _setArchived(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(employeeRepositoryProvider)
          .setDepartmentArchived(department.id, isArchived: value);
      _invalidateDepartments(ref);
    } on EmployeeException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text(
          'This permanently deletes "${department.name}". It fails if any '
          'employees or teams are still assigned to it — archive it instead '
          'if you want to keep that history.',
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
      await ref.read(employeeRepositoryProvider).deleteDepartment(department.id);
      _invalidateDepartments(ref);
    } on EmployeeException catch (error) {
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
                      department.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (department.isArchived) ...[
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
                          'Archived',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((department.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    department.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (headEmployee != null)
                  Row(
                    children: [
                      EmployeeAvatar(
                        fullName: headEmployee!.fullName,
                        photoUrl: headEmployee!.profilePhotoUrl,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Head: ${headEmployee!.fullName}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                else
                  Text(
                    'No department head assigned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(
                      label: members.length == 1
                          ? '1 employee'
                          : '${members.length} employees',
                      color: AppColors.primary,
                      icon: Icons.groups_outlined,
                    ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _AvatarStack(employees: members)),
                    ],
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
              builder: (_) => _DepartmentFormDialog(department: department),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'archive') {
                _setArchived(context, ref, !department.isArchived);
              } else if (value == 'delete') {
                _delete(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(department.isArchived ? 'Unarchive' : 'Archive'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overlapping face thumbnails for a department's members, capped to
/// [maxVisible] with a "+N" bubble for the rest — a quick "who's in here"
/// glance without listing every name.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.employees});

  final List<Employee> employees;

  static const _maxVisible = 8;
  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    const radius = _radius;
    final visible = employees.take(_maxVisible).toList();
    final overflow = employees.length - visible.length;
    final diameter = radius * 2;
    final step = radius * 1.3;
    final bubbleCount = visible.length + (overflow > 0 ? 1 : 0);
    final width = diameter + step * (bubbleCount - 1);

    return SizedBox(
      height: diameter + 4,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: step * i,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 2),
                  ),
                ),
                child: EmployeeAvatar(
                  fullName: visible[i].fullName,
                  photoUrl: visible[i].profilePhotoUrl,
                  radius: radius,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: step * visible.length,
              child: Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fieldFill,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 2),
                  ),
                ),
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DepartmentFormDialog extends ConsumerStatefulWidget {
  const _DepartmentFormDialog({required this.department});

  final Department? department;

  @override
  ConsumerState<_DepartmentFormDialog> createState() =>
      _DepartmentFormDialogState();
}

class _DepartmentFormDialogState
    extends ConsumerState<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _headEmployeeId;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.department != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name);
    _descriptionController = TextEditingController(
      text: widget.department?.description,
    );
    _headEmployeeId = widget.department?.headEmployeeId;
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
      final repository = ref.read(employeeRepositoryProvider);
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      if (_isEditing) {
        await repository.updateDepartment(
          widget.department!.id,
          name: name,
          description: description,
          headEmployeeId: _headEmployeeId,
        );
      } else {
        await repository.createDepartment(
          name: name,
          description: description,
          headEmployeeId: _headEmployeeId,
        );
      }
      _invalidateDepartments(ref);
      if (mounted) Navigator.of(context).pop();
    } on EmployeeException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit department' : 'Add department'),
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
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name'),
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
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load employees.'),
                data: (employees) {
                  final validValue =
                      employees.any((e) => e.id == _headEmployeeId)
                      ? _headEmployeeId
                      : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: validValue,
                    decoration: const InputDecoration(
                      labelText: 'Department head (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      for (final employee in employees)
                        DropdownMenuItem<String?>(
                          value: employee.id,
                          child: Text(employee.fullName),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _headEmployeeId = value),
                  );
                },
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
              : Text(_isEditing ? 'Save changes' : 'Add department'),
        ),
      ],
    );
  }
}
