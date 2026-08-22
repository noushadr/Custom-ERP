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

/// Create or edit a task: title, description, assignee (restricted to the
/// viewer's authorized pool), priority, and due date.
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

  String? _assigneeEmployeeId;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assigneeEmployeeId == null) {
      setState(() => _errorMessage = 'Select an assignee.');
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
              assigneeEmployeeId: _assigneeEmployeeId!,
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
    final employeesAsync = ref.watch(employeeListProvider);

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
                        final poolIds = pool.map((e) => e.id).toSet();
                        Employee? current;
                        for (final employee in employees) {
                          if (employee.id == _assigneeEmployeeId) {
                            current = employee;
                            break;
                          }
                        }
                        final items = [
                          ...pool,
                          if (current != null && !poolIds.contains(current.id))
                            current,
                        ];
                        return DropdownButtonFormField<String>(
                          initialValue: _assigneeEmployeeId,
                          decoration: const InputDecoration(
                            labelText: 'Assignee',
                          ),
                          items: [
                            for (final employee in items)
                              DropdownMenuItem(
                                value: employee.id,
                                child: Text(employee.fullName),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (value) =>
                                    setState(() => _assigneeEmployeeId = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
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
