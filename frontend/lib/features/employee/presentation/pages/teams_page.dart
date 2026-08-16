import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/team.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_status_badges.dart';

/// Refetches both the archived and non-archived team lists — mirrors
/// [_invalidateDepartments] in departments_page.dart for the same reason:
/// [teamsManagementProvider] is keyed by that bool, so invalidating the bare
/// family reference isn't guaranteed to refresh whichever instance is
/// currently on screen.
void _invalidateTeams(WidgetRef ref) {
  ref.invalidate(teamsManagementProvider(true));
  ref.invalidate(teamsManagementProvider(false));
  ref.invalidate(teamsProvider);
}

/// Lets Super Admin/HR-Manager view, create, edit, archive, and delete
/// teams. Requires `teams.manage`.
class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsManagementProvider(_includeArchived));
    final employeesAsync = ref.watch(employeeListProvider);
    final employees = employeesAsync.valueOrNull ?? const [];
    final employeesById = {for (final employee in employees) employee.id: employee};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
        actions: [
          IconButton(
            tooltip: 'Add team',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _TeamFormDialog(team: null),
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
                child: teamsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Could not load teams. Please try again.'),
                  ),
                  data: (teams) {
                    if (teams.isEmpty) {
                      return Center(
                        child: Text(
                          _includeArchived
                              ? 'No teams yet.'
                              : 'No active teams. Turn on "Show archived" to see archived ones.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: teams.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final leadEmployee =
                            employeesById[team.leadEmployeeId];
                        final members = employees
                            .where((e) => e.team?.id == team.id)
                            .toList();
                        return _TeamCard(
                          team: team,
                          leadEmployee: leadEmployee,
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

class _TeamCard extends ConsumerWidget {
  const _TeamCard({
    required this.team,
    required this.leadEmployee,
    required this.members,
  });

  final Team team;
  final Employee? leadEmployee;
  final List<Employee> members;

  Future<void> _setArchived(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(employeeRepositoryProvider)
          .setTeamArchived(team.id, isArchived: value);
      _invalidateTeams(ref);
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
        title: const Text('Delete team?'),
        content: Text(
          'This permanently deletes "${team.name}". It fails if any '
          'employees are still assigned to it — archive it instead if you '
          'want to keep that history.',
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
      await ref.read(employeeRepositoryProvider).deleteTeam(team.id);
      _invalidateTeams(ref);
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
                      team.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (team.isArchived) ...[
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
                if ((team.departmentName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Department: ${team.departmentName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (leadEmployee != null)
                  Row(
                    children: [
                      EmployeeAvatar(
                        fullName: leadEmployee!.fullName,
                        photoUrl: leadEmployee!.profilePhotoUrl,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lead: ${leadEmployee!.fullName}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                else
                  Text(
                    'No team lead assigned',
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
                      Expanded(child: _TeamAvatarStack(employees: members)),
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
              builder: (_) => _TeamFormDialog(team: team),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'archive') {
                _setArchived(context, ref, !team.isArchived);
              } else if (value == 'delete') {
                _delete(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(team.isArchived ? 'Unarchive' : 'Archive'),
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

/// Overlapping face thumbnails for a team's members — same treatment as
/// departments_page.dart's `_AvatarStack`, duplicated locally since that one
/// is private to its file.
class _TeamAvatarStack extends StatelessWidget {
  const _TeamAvatarStack({required this.employees});

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

class _TeamFormDialog extends ConsumerStatefulWidget {
  const _TeamFormDialog({required this.team});

  final Team? team;

  @override
  ConsumerState<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends ConsumerState<_TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _departmentId;
  String? _leadEmployeeId;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team?.name);
    _departmentId = widget.team?.departmentId;
    _leadEmployeeId = widget.team?.leadEmployeeId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departmentId == null) {
      setState(() => _errorMessage = 'Department is required');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(employeeRepositoryProvider);
      final name = _nameController.text.trim();
      if (_isEditing) {
        await repository.updateTeam(
          widget.team!.id,
          name: name,
          departmentId: _departmentId!,
          leadEmployeeId: _leadEmployeeId,
        );
      } else {
        await repository.createTeam(
          name: name,
          departmentId: _departmentId!,
          leadEmployeeId: _leadEmployeeId,
        );
      }
      _invalidateTeams(ref);
      if (mounted) Navigator.of(context).pop();
    } on EmployeeException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final employeesAsync = ref.watch(employeeListProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit team' : 'Add team'),
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
              departmentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load departments.'),
                data: (departments) {
                  final validValue =
                      departments.any((d) => d.id == _departmentId)
                      ? _departmentId
                      : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: validValue,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: [
                      for (final department in departments)
                        DropdownMenuItem<String?>(
                          value: department.id,
                          child: Text(department.name),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _departmentId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load employees.'),
                data: (employees) {
                  final validValue =
                      employees.any((e) => e.id == _leadEmployeeId)
                      ? _leadEmployeeId
                      : null;
                  return DropdownButtonFormField<String?>(
                    initialValue: validValue,
                    decoration: const InputDecoration(
                      labelText: 'Team lead (optional)',
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
                        : (value) => setState(() => _leadEmployeeId = value),
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
              : Text(_isEditing ? 'Save changes' : 'Add team'),
        ),
      ],
    );
  }
}
