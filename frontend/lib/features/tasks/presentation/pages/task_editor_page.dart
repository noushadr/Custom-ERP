import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../application/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/exceptions/task_exception.dart';

/// Formats a [DateTime] as an ISO 'YYYY-MM-DD' string — same convention as
/// the Leave feature's own local `isoDate` helper.
String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Every employee the current viewer is authorized to assign a task to — all
/// active employees for a `tasks.manage` holder, or only active employees in
/// a department the viewer heads (see TasksService.canAssignTo, which this
/// mirrors).
List<Employee> _authorizedAssignees({
  required List<Employee> employees,
  required List<Department> departments,
  required Employee? myProfile,
  required bool hasOverride,
}) {
  final active = employees
      .where((e) => e.employmentStatus == 'active')
      .toList();
  if (hasOverride) return active;
  if (myProfile == null) return const [];

  final headedDepartmentIds = departments
      .where((d) => d.headEmployeeId == myProfile.id)
      .map((d) => d.id)
      .toSet();
  if (headedDepartmentIds.isEmpty) return const [];

  return active
      .where(
        (e) => e.department != null && headedDepartmentIds.contains(e.department!.id),
      )
      .toList();
}

enum _AssignTarget { individual, team }

/// Create or edit a task: title, description, assignee, priority, and due
/// date. Creating a new task offers a choice of assignment target — a
/// specific person (restricted to the viewer's authorized pool, unchanged
/// from before) or a whole team (open to anyone, no employee picker at
/// all — the team itself picks up the task afterward). Editing an existing
/// task only ever reassigns to a specific person, same as before; a team
/// task's own claim/assign flow lives on the detail page instead.
class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key, this.existingTask, this.initialProjectId});

  /// Null when creating a new task; the current task when editing.
  final Task? existingTask;

  /// Pre-fills the new task's project link — set when created from a
  /// project's detail page. Ignored when editing an existing task.
  final String? initialProjectId;

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  _AssignTarget _target = _AssignTarget.individual;
  String? _assigneeEmployeeId;
  String? _departmentId;
  late String _priority;
  DateTime? _dueDate;

  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _assigneeEmployeeId = existing?.assigneeEmployeeId;
    _priority = existing?.priority ?? TaskPriority.medium;
    _dueDate = existing != null ? DateTime.parse(existing.dueDate) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  /// Whether the viewer is authorized to pick a specific person at all — a
  /// `tasks.manage` holder, or anyone heading at least one department. Read
  /// fresh here (not the `build`-time pool) since an authorized viewer
  /// should still get the team-only path forced when they have nobody
  /// actually assignable yet, not just when they lack authority.
  bool _canPickPerson() {
    final authState = ref.read(authControllerProvider);
    final hasOverride =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('tasks.manage');
    if (hasOverride) return true;
    final myProfile = ref.read(myProfileProvider).valueOrNull;
    final departments = ref.read(departmentsProvider).valueOrNull ?? const [];
    return myProfile != null &&
        departments.any((d) => d.headEmployeeId == myProfile.id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final assignToTeam =
        !_isEditing &&
        (_target == _AssignTarget.team || !_canPickPerson());
    if (!assignToTeam && _assigneeEmployeeId == null) {
      setState(() => _errorMessage = 'Select an assignee.');
      return;
    }
    if (assignToTeam && _departmentId == null) {
      setState(() => _errorMessage = 'Select a team.');
      return;
    }
    if (_dueDate == null) {
      setState(() => _errorMessage = 'Select a due date.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final description = _descriptionController.text.trim();
    final repository = ref.read(taskRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateTask(
              widget.existingTask!.id,
              title: _titleController.text.trim(),
              description: description,
              assigneeEmployeeId: _assigneeEmployeeId,
              priority: _priority,
              dueDate: _isoDate(_dueDate!),
            )
          : await repository.createTask(
              title: _titleController.text.trim(),
              description: description.isEmpty ? null : description,
              assigneeEmployeeId: assignToTeam ? null : _assigneeEmployeeId,
              departmentId: assignToTeam ? _departmentId : null,
              priority: _priority,
              dueDate: _isoDate(_dueDate!),
              projectId: widget.initialProjectId,
            );

      if (widget.initialProjectId != null) {
        ref.invalidate(tasksByProjectProvider(widget.initialProjectId!));
      }

      ref.invalidate(myTasksProvider);
      ref.invalidate(tasksAssignedByMeProvider);
      ref.invalidate(teamTasksProvider);
      ref.invalidate(claimableTasksProvider);
      ref.invalidate(taskProvider(saved.id));
      if (_isEditing) ref.invalidate(taskHistoryProvider(saved.id));
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on TaskException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hasOverride =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('tasks.manage');
    final myProfile = ref.watch(myProfileProvider).valueOrNull;
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final canPickPerson =
        _isEditing ||
        hasOverride ||
        (myProfile != null &&
            departments.any((d) => d.headEmployeeId == myProfile.id));
    // A plain employee has no permission to list all employees at all, so
    // only fetch that list when it's actually needed for a person picker —
    // otherwise the 403 it'd get back would block the team-only picker too.
    final employeesAsync = canPickPerson
        ? ref.watch(employeeListProvider)
        : const AsyncValue<List<Employee>>.data(<Employee>[]);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    employeesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) =>
                          const Text('Could not load employees.'),
                      data: (employees) {
                        final pool = _authorizedAssignees(
                          employees: employees,
                          departments: departments,
                          myProfile: myProfile,
                          hasOverride: hasOverride,
                        );
                        if (!_isEditing && canPickPerson) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedButton<_AssignTarget>(
                                segments: const [
                                  ButtonSegment(
                                    value: _AssignTarget.individual,
                                    label: Text('Assign to person'),
                                  ),
                                  ButtonSegment(
                                    value: _AssignTarget.team,
                                    label: Text('Assign to team'),
                                  ),
                                ],
                                selected: {_target},
                                onSelectionChanged: _submitting
                                    ? null
                                    : (selection) => setState(
                                        () => _target = selection.first,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              if (_target == _AssignTarget.team)
                                _TeamPicker(
                                  departments: departments,
                                  selectedDepartmentId: _departmentId,
                                  enabled: !_submitting,
                                  onChanged: (value) =>
                                      setState(() => _departmentId = value),
                                )
                              else
                                _AssigneePicker(
                                  pool: pool,
                                  employees: employees,
                                  selectedEmployeeId: _assigneeEmployeeId,
                                  enabled: !_submitting,
                                  onChanged: (value) => setState(
                                    () => _assigneeEmployeeId = value,
                                  ),
                                ),
                            ],
                          );
                        }

                        if (!canPickPerson) {
                          // A plain employee creating a task: always a team
                          // task, no toggle, no employee picker at all.
                          return _TeamPicker(
                            departments: departments,
                            selectedDepartmentId: _departmentId,
                            enabled: !_submitting,
                            onChanged: (value) =>
                                setState(() => _departmentId = value),
                          );
                        }

                        // Editing an existing task: unchanged, always a
                        // specific-person picker.
                        return _AssigneePicker(
                          pool: pool,
                          employees: employees,
                          selectedEmployeeId: _assigneeEmployeeId,
                          enabled: !_submitting,
                          onChanged: (value) =>
                              setState(() => _assigneeEmployeeId = value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        for (final priority in TaskPriority.values)
                          DropdownMenuItem(
                            value: priority,
                            child: Text(
                              priority[0].toUpperCase() + priority.substring(1),
                            ),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      key: const Key('task-due-date'),
                      onTap: _submitting ? null : _pickDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                        ),
                        child: Text(
                          _dueDate == null ? '—' : _isoDate(_dueDate!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Create Task'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneePicker extends StatelessWidget {
  const _AssigneePicker({
    required this.pool,
    required this.employees,
    required this.selectedEmployeeId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Employee> pool;
  final List<Employee> employees;
  final String? selectedEmployeeId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final poolIds = pool.map((e) => e.id).toSet();
    Employee? current;
    for (final employee in employees) {
      if (employee.id == selectedEmployeeId) {
        current = employee;
        break;
      }
    }
    final items = [
      ...pool,
      if (current != null && !poolIds.contains(current.id)) current,
    ];
    return DropdownButtonFormField<String>(
      initialValue: selectedEmployeeId,
      decoration: const InputDecoration(labelText: 'Assignee'),
      items: [
        for (final employee in items)
          DropdownMenuItem(value: employee.id, child: Text(employee.fullName)),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}

/// A plain department picker — used both by anyone assigning a new task to
/// a team (no authority check needed) and, implicitly, has no restricted
/// pool the way [_AssigneePicker] does.
class _TeamPicker extends StatelessWidget {
  const _TeamPicker({
    required this.departments,
    required this.selectedDepartmentId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Department> departments;
  final String? selectedDepartmentId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedDepartmentId,
      decoration: const InputDecoration(labelText: 'Team'),
      items: [
        for (final department in departments)
          DropdownMenuItem(value: department.id, child: Text(department.name)),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}
