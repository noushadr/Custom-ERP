import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/goal_providers.dart';
import '../../domain/entities/goal.dart';
import '../../domain/exceptions/goal_exception.dart';

/// Lets Admin/HR (`goals.manage`) set and edit a goal for any employee, or
/// bulk-assign one goal to every active employee in a department; a Team
/// Lead without that permission gets the same tools scoped to just their
/// own direct reports. Employees see their own goals read-only on their
/// dashboard instead (`UserDashboardPage`'s "My Goals" section), not here.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final canManageGoals =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('goals.manage');
    final directReportsAsync = ref.watch(myDirectReportsProvider);
    final hasDirectReports =
        directReportsAsync.valueOrNull?.isNotEmpty ?? false;

    if (!canManageGoals && !hasDirectReports) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Center(
          child: Text(
            "Goals are set by your manager or HR/Admin — you'll see your "
            'own on your dashboard.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        canManageGoals ? 'All Goals' : "My Team's Goals",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _AddGoalDialog(canManageGoals: canManageGoals),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GoalsList(canManageGoals: canManageGoals),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends ConsumerStatefulWidget {
  const _GoalsList({required this.canManageGoals});

  final bool canManageGoals;

  @override
  ConsumerState<_GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends ConsumerState<_GoalsList> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _departmentFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Goal> _applyFilters(List<Goal> goals) {
    return goals.where((goal) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          goal.employeeName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDepartment =
          _departmentFilter == null || goal.departmentId == _departmentFilter;
      return matchesSearch && matchesDepartment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(
      widget.canManageGoals ? allGoalsProvider : teamGoalsProvider,
    );
    final departmentsAsync = ref.watch(departmentsProvider);

    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by employee name',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: departmentsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (departments) => DropdownButtonFormField<String?>(
                    initialValue: _departmentFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All departments'),
                      ),
                      for (final department in departments)
                        DropdownMenuItem(
                          value: department.id,
                          child: Text(department.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _departmentFilter = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          goalsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('Could not load goals.'),
            data: (goals) {
              final filtered = _applyFilters(goals);
              if (filtered.isEmpty) {
                return Text(
                  goals.isEmpty
                      ? 'No goals set yet.'
                      : 'No goals match your filters.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return _GoalCardGrid(
                goals: filtered,
                canManageGoals: widget.canManageGoals,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Responsive card grid — three per row once there's comfortable room,
/// stepping down on narrower screens, same breakpoints and
/// IntrinsicHeight-row approach as `EmployeeDirectoryPage`'s card grid, so
/// every card in a row matches height regardless of its content length.
class _GoalCardGrid extends StatelessWidget {
  const _GoalCardGrid({required this.goals, required this.canManageGoals});

  final List<Goal> goals;
  final bool canManageGoals;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final rows = <List<Goal>>[
          for (var i = 0; i < goals.length; i += columns)
            goals.sublist(
              i,
              i + columns > goals.length ? goals.length : i + columns,
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < row.length; i++) ...[
                      SizedBox(
                        width: cardWidth,
                        child: _GoalCard(
                          goal: row[i],
                          canManageGoals: canManageGoals,
                        ),
                      ),
                      if (i != row.length - 1) const SizedBox(width: spacing),
                    ],
                  ],
                ),
              ),
              if (row != rows.last) const SizedBox(height: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.canManageGoals});

  final Goal goal;
  final bool canManageGoals;

  Future<void> _archive(WidgetRef ref, BuildContext context) async {
    try {
      final repository = ref.read(goalRepositoryProvider);
      if (canManageGoals) {
        await repository.archive(goal.id);
      } else {
        await repository.archiveAsManager(goal.id);
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(teamGoalsProvider);
    } on GoalException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmployeeAvatar(
                  fullName: goal.employeeName,
                  photoUrl: goal.employeePhotoUrl,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.employeeName,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (goal.departmentName != null)
                        Text(
                          goal.departmentName!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _EditGoalDialog(
                      goal: goal,
                      canManageGoals: canManageGoals,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () => _archive(ref, context),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  tooltip: 'Archive',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              goal.title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 4),
              Text(
                goal.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.achievementPercentage / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.borderSubtle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.achievementPercentage}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Set by ${goal.createdByName} · '
              '${formatDisplayDateTime(goal.createdAt)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalDialog extends ConsumerStatefulWidget {
  const _AddGoalDialog({required this.canManageGoals});

  final bool canManageGoals;

  @override
  ConsumerState<_AddGoalDialog> createState() => _AddGoalDialogState();
}

enum _AssignTarget { individual, department }

class _AddGoalDialogState extends ConsumerState<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  _AssignTarget _target = _AssignTarget.individual;
  String? _selectedEmployeeId;
  String? _selectedDepartmentId;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(goalRepositoryProvider);
      if (_target == _AssignTarget.department) {
        final departmentId = _selectedDepartmentId;
        if (departmentId == null) {
          setState(() => _errorMessage = 'Choose a department');
          return;
        }
        await repository.bulkAssignToDepartment(
          departmentId: departmentId,
          title: _titleController.text,
          description: description,
        );
      } else {
        final employeeId = _selectedEmployeeId;
        if (employeeId == null) {
          setState(() => _errorMessage = 'Choose an employee');
          return;
        }
        if (widget.canManageGoals) {
          await repository.createForEmployee(
            employeeId: employeeId,
            title: _titleController.text,
            description: description,
          );
        } else {
          await repository.createForMyDirectReport(
            employeeId: employeeId,
            title: _titleController.text,
            description: description,
          );
        }
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(teamGoalsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on GoalException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Goal'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.canManageGoals) ...[
                SegmentedButton<_AssignTarget>(
                  segments: const [
                    ButtonSegment(
                      value: _AssignTarget.individual,
                      label: Text('Individual'),
                    ),
                    ButtonSegment(
                      value: _AssignTarget.department,
                      label: Text('Whole department'),
                    ),
                  ],
                  selected: {_target},
                  onSelectionChanged: _submitting
                      ? null
                      : (selection) =>
                            setState(() => _target = selection.first),
                ),
                const SizedBox(height: 12),
              ],
              if (_target == _AssignTarget.individual)
                _EmployeePicker(
                  scopeToDirectReports: !widget.canManageGoals,
                  selectedEmployeeId: _selectedEmployeeId,
                  enabled: !_submitting,
                  onChanged: (value) =>
                      setState(() => _selectedEmployeeId = value),
                )
              else
                _DepartmentPicker(
                  selectedDepartmentId: _selectedDepartmentId,
                  enabled: !_submitting,
                  onChanged: (value) =>
                      setState(() => _selectedDepartmentId = value),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _EditGoalDialog extends ConsumerStatefulWidget {
  const _EditGoalDialog({required this.goal, required this.canManageGoals});

  final Goal goal;
  final bool canManageGoals;

  @override
  ConsumerState<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends ConsumerState<_EditGoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _achievementPercentage;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(
      text: widget.goal.description ?? '',
    );
    _achievementPercentage = widget.goal.achievementPercentage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(goalRepositoryProvider);
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      if (widget.canManageGoals) {
        await repository.update(
          widget.goal.id,
          title: _titleController.text,
          description: description,
          achievementPercentage: _achievementPercentage,
        );
      } else {
        await repository.updateAsManager(
          widget.goal.id,
          title: _titleController.text,
          description: description,
        );
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(teamGoalsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on GoalException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goal.employeeName),
      content: SizedBox(
        width: 380,
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
            TextField(
              controller: _titleController,
              enabled: !_submitting,
              decoration: const InputDecoration(labelText: 'Goal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_submitting,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            if (widget.canManageGoals) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Achieved',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '$_achievementPercentage%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _achievementPercentage.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$_achievementPercentage%',
                onChanged: _submitting
                    ? null
                    : (value) =>
                          setState(() => _achievementPercentage = value.round()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _EmployeePicker extends ConsumerWidget {
  const _EmployeePicker({
    required this.scopeToDirectReports,
    required this.selectedEmployeeId,
    required this.enabled,
    required this.onChanged,
  });

  final bool scopeToDirectReports;
  final String? selectedEmployeeId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(
      scopeToDirectReports ? myDirectReportsProvider : employeeListProvider,
    );

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Could not load employees.'),
      data: (employees) => DropdownButtonFormField<String>(
        initialValue: selectedEmployeeId,
        decoration: const InputDecoration(labelText: 'Employee'),
        items: [
          for (final Employee employee in employees)
            DropdownMenuItem(
              value: employee.id,
              child: Text(employee.fullName),
            ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _DepartmentPicker extends ConsumerWidget {
  const _DepartmentPicker({
    required this.selectedDepartmentId,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedDepartmentId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Could not load departments.'),
      data: (departments) => DropdownButtonFormField<String>(
        initialValue: selectedDepartmentId,
        decoration: const InputDecoration(labelText: 'Department'),
        items: [
          for (final Department department in departments)
            DropdownMenuItem(
              value: department.id,
              child: Text(department.name),
            ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
