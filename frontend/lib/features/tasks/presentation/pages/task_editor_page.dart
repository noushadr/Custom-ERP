import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../clients/application/clients_providers.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/domain/entities/project.dart';
import '../../../clients/domain/entities/project_type.dart';
import '../../../clients/domain/exceptions/client_exception.dart';
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
        (e) =>
            e.department != null &&
            headedDepartmentIds.contains(e.department!.id),
      )
      .toList();
}

enum _AssignTarget { individual, team }

/// Create or edit a task: title, description, assignee, priority, due date,
/// and an optional client/project link. Creating a new task offers a choice
/// of assignment target — a specific person (restricted to the viewer's
/// authorized pool, unchanged from before) or a whole team (open to anyone,
/// no employee picker at all — the team itself picks up the task
/// afterward). Editing an existing task only ever reassigns to a specific
/// person, same as before; a team task's own claim/assign flow lives on the
/// detail page instead.
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
  // Low preselected, per explicit instruction — was Medium before.
  String _priority = TaskPriority.low;
  DateTime? _dueDate;
  String? _projectId;

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
    _priority = existing?.priority ?? TaskPriority.low;
    _dueDate = existing != null ? DateTime.parse(existing.dueDate) : null;
    _projectId = existing?.projectId ?? widget.initialProjectId;
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
        !_isEditing && (_target == _AssignTarget.team || !_canPickPerson());
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
              projectId: _projectId,
            )
          : await repository.createTask(
              title: _titleController.text.trim(),
              description: description.isEmpty ? null : description,
              assigneeEmployeeId: assignToTeam ? null : _assigneeEmployeeId,
              departmentId: assignToTeam ? _departmentId : null,
              priority: _priority,
              dueDate: _isoDate(_dueDate!),
              projectId: _projectId,
            );

      if (widget.initialProjectId != null) {
        ref.invalidate(tasksByProjectProvider(widget.initialProjectId!));
      }
      if (_projectId != null && _projectId != widget.initialProjectId) {
        ref.invalidate(tasksByProjectProvider(_projectId!));
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final left = _LeftColumn(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                        );
                        final right = _RightColumn(
                          isEditing: _isEditing,
                          submitting: _submitting,
                          target: _target,
                          onTargetChanged: (value) =>
                              setState(() => _target = value),
                          canPickPerson: canPickPerson,
                          employeesAsync: employeesAsync,
                          departments: departments,
                          myProfile: myProfile,
                          hasOverride: hasOverride,
                          assigneeEmployeeId: _assigneeEmployeeId,
                          onAssigneeChanged: (value) =>
                              setState(() => _assigneeEmployeeId = value),
                          departmentId: _departmentId,
                          onDepartmentChanged: (value) =>
                              setState(() => _departmentId = value),
                          priority: _priority,
                          onPriorityChanged: (value) =>
                              setState(() => _priority = value),
                          dueDate: _dueDate,
                          onPickDueDate: _pickDueDate,
                          projectId: _projectId,
                          onProjectChanged: (project) =>
                              setState(() => _projectId = project?.id),
                        );

                        if (constraints.maxWidth >= 680) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: left),
                              const SizedBox(width: 28),
                              SizedBox(width: 320, child: right),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [left, const SizedBox(height: 24), right],
                        );
                      },
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

/// Title + description — the two fields worth full-width room to breathe,
/// kept on the left in the wide layout so they read like the "document"
/// while the right column reads like the task's metadata sidebar.
class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.titleController,
    required this.descriptionController,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'What needs to get done?',
          ),
          style: Theme.of(context).textTheme.titleMedium,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Add any extra detail, context, or links…',
            alignLabelWithHint: true,
          ),
          maxLines: 10,
          minLines: 8,
        ),
      ],
    );
  }
}

/// Everything else: assignment, priority, due date, and the optional
/// client/project link — the task's metadata, grouped together on the
/// right in the wide layout.
class _RightColumn extends ConsumerWidget {
  const _RightColumn({
    required this.isEditing,
    required this.submitting,
    required this.target,
    required this.onTargetChanged,
    required this.canPickPerson,
    required this.employeesAsync,
    required this.departments,
    required this.myProfile,
    required this.hasOverride,
    required this.assigneeEmployeeId,
    required this.onAssigneeChanged,
    required this.departmentId,
    required this.onDepartmentChanged,
    required this.priority,
    required this.onPriorityChanged,
    required this.dueDate,
    required this.onPickDueDate,
    required this.projectId,
    required this.onProjectChanged,
  });

  final bool isEditing;
  final bool submitting;
  final _AssignTarget target;
  final ValueChanged<_AssignTarget> onTargetChanged;
  final bool canPickPerson;
  final AsyncValue<List<Employee>> employeesAsync;
  final List<Department> departments;
  final Employee? myProfile;
  final bool hasOverride;
  final String? assigneeEmployeeId;
  final ValueChanged<String?> onAssigneeChanged;
  final String? departmentId;
  final ValueChanged<String?> onDepartmentChanged;
  final String priority;
  final ValueChanged<String> onPriorityChanged;
  final DateTime? dueDate;
  final VoidCallback onPickDueDate;
  final String? projectId;
  final ValueChanged<Project?> onProjectChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignment', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        employeesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could not load employees.'),
          data: (employees) {
            final pool = _authorizedAssignees(
              employees: employees,
              departments: departments,
              myProfile: myProfile,
              hasOverride: hasOverride,
            );
            if (!isEditing && canPickPerson) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<_AssignTarget>(
                    segments: const [
                      ButtonSegment(
                        value: _AssignTarget.individual,
                        label: Text('Person'),
                      ),
                      ButtonSegment(
                        value: _AssignTarget.team,
                        label: Text('Team'),
                      ),
                    ],
                    selected: {target},
                    onSelectionChanged: submitting
                        ? null
                        : (selection) => onTargetChanged(selection.first),
                  ),
                  const SizedBox(height: 12),
                  if (target == _AssignTarget.team)
                    _SearchableEntityField<Department>(
                      label: 'Team',
                      hintText: 'Search teams…',
                      options: departments,
                      displayStringForOption: (d) => d.name,
                      initialText: departments
                          .where((d) => d.id == departmentId)
                          .map((d) => d.name)
                          .firstOrElse(''),
                      enabled: !submitting,
                      onSelected: (d) => onDepartmentChanged(d.id),
                    )
                  else
                    _SearchableEntityField<Employee>(
                      label: 'Assignee',
                      hintText: 'Search people…',
                      options: pool,
                      displayStringForOption: (e) => e.fullName,
                      initialText: employees
                          .where((e) => e.id == assigneeEmployeeId)
                          .map((e) => e.fullName)
                          .firstOrElse(''),
                      enabled: !submitting,
                      onSelected: (e) => onAssigneeChanged(e.id),
                    ),
                ],
              );
            }

            if (!canPickPerson) {
              // A plain employee creating a task: always a team task, no
              // toggle, no employee picker at all.
              return _SearchableEntityField<Department>(
                label: 'Team',
                hintText: 'Search teams…',
                options: departments,
                displayStringForOption: (d) => d.name,
                initialText: departments
                    .where((d) => d.id == departmentId)
                    .map((d) => d.name)
                    .firstOrElse(''),
                enabled: !submitting,
                onSelected: (d) => onDepartmentChanged(d.id),
              );
            }

            // Editing an existing task: unchanged, always a specific-person
            // picker.
            return _SearchableEntityField<Employee>(
              label: 'Assignee',
              hintText: 'Search people…',
              options: pool,
              displayStringForOption: (e) => e.fullName,
              initialText: employees
                  .where((e) => e.id == assigneeEmployeeId)
                  .map((e) => e.fullName)
                  .firstOrElse(''),
              enabled: !submitting,
              onSelected: (e) => onAssigneeChanged(e.id),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Priority', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in TaskPriority.values)
              ChoiceChip(
                label: Text(value[0].toUpperCase() + value.substring(1)),
                selected: priority == value,
                onSelected: submitting
                    ? null
                    : (selected) {
                        if (selected) onPriorityChanged(value);
                      },
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Due date', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('task-due-date'),
          onTap: submitting ? null : onPickDueDate,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Text(dueDate == null ? 'Select a date' : _isoDate(dueDate!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Client / Project', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _ClientProjectField(
          selectedProjectId: projectId,
          enabled: !submitting,
          onChanged: onProjectChanged,
        ),
      ],
    );
  }
}

extension _FirstOrElse<T> on Iterable<T> {
  /// Like `firstWhere` with an eager fallback — used here purely to resolve
  /// "the display text for whatever's currently selected, or blank if
  /// nothing/not-found-yet" without pulling in package:collection just for
  /// `firstOrNull`.
  T firstOrElse(T fallback) => isEmpty ? fallback : first;
}

/// A generic type-ahead field — Flutter's own `Autocomplete`, no new
/// dependency — used for every searchable picker on this page (assignee,
/// team, client/project). Selecting an option is the only way to set a
/// value; free text alone does nothing, matching the previous dropdowns'
/// all-or-nothing behavior.
class _SearchableEntityField<T extends Object> extends StatelessWidget {
  const _SearchableEntityField({
    required this.label,
    required this.hintText,
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    this.initialText = '',
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final List<T> options;
  final String Function(T) displayStringForOption;
  final ValueChanged<T> onSelected;
  final String initialText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      initialValue: TextEditingValue(text: initialText),
      displayStringForOption: displayStringForOption,
      optionsBuilder: (textEditingValue) {
        if (!enabled) return const Iterable.empty();
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where(
          (option) =>
              displayStringForOption(option).toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minWidth: 260),
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No matches.'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(displayStringForOption(option)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Search-and-select a Client & Projects project (shown as "{project} —
/// {client}", so picking effectively picks a client too), with a fallback
/// to add a brand-new client (and a minimal new project for them, since a
/// task can only link to a project, not a bare client) right from here —
/// no need to leave this page and go create one in Clients & Projects
/// first.
class _ClientProjectField extends ConsumerStatefulWidget {
  const _ClientProjectField({
    required this.selectedProjectId,
    required this.enabled,
    required this.onChanged,
  });

  final String? selectedProjectId;
  final bool enabled;
  final ValueChanged<Project?> onChanged;

  @override
  ConsumerState<_ClientProjectField> createState() =>
      _ClientProjectFieldState();
}

class _ClientProjectFieldState extends ConsumerState<_ClientProjectField> {
  Project? _selected;

  Future<void> _addNewClient() async {
    final client = await _showQuickAddClientDialog(context, ref);
    if (client == null || !mounted) return;
    ref.invalidate(clientsListProvider(false));

    final project = await _showQuickAddProjectDialog(context, ref, client);
    if (project == null || !mounted) return;
    ref.invalidate(projectsListProvider((status: null, clientId: null)));
    setState(() => _selected = project);
    widget.onChanged(project);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(
      projectsListProvider((status: null, clientId: null)),
    );
    return projectsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('Could not load clients/projects.'),
      data: (projects) {
        Project? matchingExisting;
        for (final project in projects) {
          if (project.id == widget.selectedProjectId) {
            matchingExisting = project;
            break;
          }
        }
        final current = _selected ?? matchingExisting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchableEntityField<Project>(
              label: 'Client / Project (optional)',
              hintText: 'Search clients or projects…',
              options: projects,
              displayStringForOption: (p) => '${p.name} — ${p.clientName}',
              initialText: current == null
                  ? ''
                  : '${current.name} — ${current.clientName}',
              enabled: widget.enabled,
              onSelected: (p) {
                setState(() => _selected = p);
                widget.onChanged(p);
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.enabled ? _addNewClient : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Can't find your client? Add new"),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A minimal "new client" dialog — just the company/client name, which is
/// the only field `createClient` actually requires; the full client form in
/// Clients & Projects still covers everything else (industry, website,
/// primary contact, ...) for later.
Future<Client?> _showQuickAddClientDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  var submitting = false;
  String? error;

  return showDialog<Client>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('New client'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Client / Company name',
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting
                ? null
                : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.length < 2) {
                      setState(() => error = 'Enter a client name.');
                      return;
                    }
                    setState(() {
                      submitting = true;
                      error = null;
                    });
                    try {
                      final client = await ref
                          .read(clientsRepositoryProvider)
                          .createClient(companyName: name);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(client);
                      }
                    } on ClientException catch (e) {
                      setState(() {
                        submitting = false;
                        error = e.message;
                      });
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

/// A minimal "new project" dialog — just enough to link a brand-new client
/// to a task (name/type/start date, matching `createProject`'s required
/// fields); the full project form in Clients & Projects still covers
/// everything else (package, services, renewal date, ...) for later.
Future<Project?> _showQuickAddProjectDialog(
  BuildContext context,
  WidgetRef ref,
  Client client,
) {
  final nameController = TextEditingController();
  var type = ProjectType.oneTime;
  var startDate = DateTime.now();
  var submitting = false;
  String? error;

  return showDialog<Project>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text('New project for ${client.companyName}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Project name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: ProjectType.oneTime,
                    label: Text('One-time'),
                  ),
                  ButtonSegment(
                    value: ProjectType.retainer,
                    label: Text('Retainer'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (selection) =>
                    setState(() => type = selection.first),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: startDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start date'),
                  child: Text(_isoDate(startDate)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting
                ? null
                : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() => error = 'Enter a project name.');
                      return;
                    }
                    setState(() {
                      submitting = true;
                      error = null;
                    });
                    try {
                      final project = await ref
                          .read(clientsRepositoryProvider)
                          .createProject(
                            clientId: client.id,
                            name: name,
                            type: type,
                            startDate: _isoDate(startDate),
                          );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(project);
                      }
                    } on ClientException catch (e) {
                      setState(() {
                        submitting = false;
                        error = e.message;
                      });
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
