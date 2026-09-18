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

/// Who's looking at this page, from most to least broad reach — decides
/// which goals are listed, what "Add Goal" creates, and what Edit/Archive
/// are allowed to touch. [admin] (`goals.manage`) manages any employee's
/// goals; [teamLead] (no permission, identity-scoped) manages only their
/// own direct reports'; [self] (neither of the above) manages only their
/// own — set, edited, and archived with no HR/Admin approval step, same as
/// every other mode.
enum _GoalViewerMode { admin, teamLead, self }

/// Lets Admin/HR (`goals.manage`) set and edit a goal for any employee, or
/// bulk-assign one goal to every active employee in a department; a Team
/// Lead without that permission gets the same tools scoped to just their
/// own direct reports; any other employee gets it scoped to just
/// themselves — no approval needed, same as the other two modes.
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

    final mode = canManageGoals
        ? _GoalViewerMode.admin
        : hasDirectReports
        ? _GoalViewerMode.teamLead
        : _GoalViewerMode.self;
    final title = switch (mode) {
      _GoalViewerMode.admin => 'All Goals',
      _GoalViewerMode.teamLead => "My Goals & Team's Goals",
      _GoalViewerMode.self => 'My Goals',
    };

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
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _AddGoalDialog(mode: mode),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _GoalsList(mode: mode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends ConsumerStatefulWidget {
  const _GoalsList({required this.mode});

  final _GoalViewerMode mode;

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
    final goalsAsync = ref.watch(switch (widget.mode) {
      _GoalViewerMode.admin => allGoalsProvider,
      _GoalViewerMode.teamLead => myAndTeamGoalsProvider,
      _GoalViewerMode.self => myGoalsProvider,
    });
    final departmentsAsync = ref.watch(departmentsProvider);
    // A plain employee's list is only ever their own goals — searching by
    // employee name or filtering by department would just be clutter here.
    final showSearch = widget.mode != _GoalViewerMode.self;
    // A Team Lead's list is always just themselves + their own direct
    // reports (typically all one department already) — a department filter
    // over that small, already-scoped set adds nothing. Admin/HR's list
    // spans the whole company, where it's actually useful.
    final showDepartmentFilter = widget.mode == _GoalViewerMode.admin;
    // A Team Lead needs to tell their own goals from a report's on a card —
    // resolved once here (not per-card) from the same identity check the
    // "Myself" option in the Add Goal picker uses.
    final selfIdAsync = widget.mode == _GoalViewerMode.teamLead
        ? ref.watch(myProfileProvider)
        : null;

    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSearch) ...[
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
                if (showDepartmentFilter) ...[
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
              ],
            ),
            const SizedBox(height: 16),
          ],
          goalsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('Could not load goals.'),
            data: (goals) {
              final filtered = showSearch
                  ? _applyFilters(goals)
                  : goals;
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
                mode: widget.mode,
                selfEmployeeId: selfIdAsync?.valueOrNull?.id,
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
  const _GoalCardGrid({
    required this.goals,
    required this.mode,
    this.selfEmployeeId,
  });

  final List<Goal> goals;
  final _GoalViewerMode mode;

  /// The viewer's own employee id — only passed for [_GoalViewerMode.teamLead],
  /// so each card can tell "my own goal" (self-scoped actions) from "a
  /// report's goal" (manager-scoped actions) within the same combined list.
  final String? selfEmployeeId;

  /// [mode] as-is, except in [_GoalViewerMode.teamLead] a card for the
  /// viewer's own goal (as opposed to a direct report's) resolves to
  /// [_GoalViewerMode.self] instead, so its edit/archive route to the
  /// `/me` endpoints and its edit dialog shows the achievement slider.
  _GoalViewerMode _effectiveMode(Goal goal) {
    if (mode == _GoalViewerMode.teamLead && goal.employeeId == selfEmployeeId) {
      return _GoalViewerMode.self;
    }
    return mode;
  }

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
                          mode: _effectiveMode(row[i]),
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
  const _GoalCard({required this.goal, required this.mode});

  final Goal goal;
  final _GoalViewerMode mode;

  Future<void> _archive(WidgetRef ref, BuildContext context) async {
    try {
      final repository = ref.read(goalRepositoryProvider);
      switch (mode) {
        case _GoalViewerMode.admin:
          await repository.archive(goal.id);
        case _GoalViewerMode.teamLead:
          await repository.archiveAsManager(goal.id);
        case _GoalViewerMode.self:
          await repository.archiveAsSelf(goal.id);
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(teamGoalsProvider);
      ref.invalidate(myGoalsProvider);
      ref.invalidate(myAndTeamGoalsProvider);
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
                    builder: (_) => _EditGoalDialog(goal: goal, mode: mode),
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
  const _AddGoalDialog({required this.mode});

  final _GoalViewerMode mode;

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
      if (widget.mode == _GoalViewerMode.self) {
        await repository.createForSelf(
          title: _titleController.text,
          description: description,
        );
      } else if (_target == _AssignTarget.department) {
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
        final selfEmployeeId = ref.read(myProfileProvider).valueOrNull?.id;
        if (widget.mode == _GoalViewerMode.admin) {
          await repository.createForEmployee(
            employeeId: employeeId,
            title: _titleController.text,
            description: description,
          );
        } else if (employeeId == selfEmployeeId) {
          // A Team Lead picked "Myself" in the employee picker.
          await repository.createForSelf(
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
      ref.invalidate(myGoalsProvider);
      ref.invalidate(myAndTeamGoalsProvider);
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
    final isSelf = widget.mode == _GoalViewerMode.self;
    final canManageGoals = widget.mode == _GoalViewerMode.admin;
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
              if (canManageGoals) ...[
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
              // A self-service goal is implicitly "for me" — no employee or
              // department picker at all.
              if (!isSelf) ...[
                if (_target == _AssignTarget.individual)
                  _EmployeePicker(
                    mode: widget.mode,
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
              ],
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
  const _EditGoalDialog({required this.goal, required this.mode});

  final Goal goal;
  final _GoalViewerMode mode;

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
      switch (widget.mode) {
        case _GoalViewerMode.admin:
          await repository.update(
            widget.goal.id,
            title: _titleController.text,
            description: description,
            achievementPercentage: _achievementPercentage,
          );
        case _GoalViewerMode.teamLead:
          await repository.updateAsManager(
            widget.goal.id,
            title: _titleController.text,
            description: description,
          );
        case _GoalViewerMode.self:
          await repository.updateAsSelf(
            widget.goal.id,
            title: _titleController.text,
            description: description,
            achievementPercentage: _achievementPercentage,
          );
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(teamGoalsProvider);
      ref.invalidate(myGoalsProvider);
      ref.invalidate(myAndTeamGoalsProvider);
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
    // A Team Lead editing a direct report's goal never sets their progress;
    // Admin/HR and the employee editing their own goal both can.
    final showAchievementSlider = widget.mode != _GoalViewerMode.teamLead;
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
            if (showAchievementSlider) ...[
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
    required this.mode,
    required this.selectedEmployeeId,
    required this.enabled,
    required this.onChanged,
  });

  /// [_GoalViewerMode.admin] lists every employee; [_GoalViewerMode.teamLead]
  /// lists "Myself" first, then just this viewer's own direct reports — a
  /// Team Lead is also an employee with their own goals to set, not just
  /// their reports'. Never called with [_GoalViewerMode.self], since that
  /// mode skips this picker entirely (a self-service goal is implicitly
  /// "for me").
  final _GoalViewerMode mode;
  final String? selectedEmployeeId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == _GoalViewerMode.admin) {
      final employeesAsync = ref.watch(employeeListProvider);
      return employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Could not load employees.'),
        data: (employees) => _dropdown([
          for (final Employee employee in employees)
            (employee.id, employee.fullName),
        ]),
      );
    }

    final selfAsync = ref.watch(myProfileProvider);
    final reportsAsync = ref.watch(myDirectReportsProvider);
    if (selfAsync.isLoading || reportsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final self = selfAsync.valueOrNull;
    if (self == null || reportsAsync.hasError) {
      return const Text('Could not load employees.');
    }
    return _dropdown([
      (self.id, 'Myself'),
      for (final Employee report in reportsAsync.valueOrNull ?? const [])
        (report.id, report.fullName),
    ]);
  }

  Widget _dropdown(List<(String, String)> items) {
    return DropdownButtonFormField<String>(
      initialValue: selectedEmployeeId,
      decoration: const InputDecoration(labelText: 'Employee'),
      items: [
        for (final (id, name) in items)
          DropdownMenuItem(value: id, child: Text(name)),
      ],
      onChanged: enabled ? onChanged : null,
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
