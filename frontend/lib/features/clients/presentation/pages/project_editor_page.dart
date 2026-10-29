import '../../../../shared/utils/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/hybrid_badge.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_status.dart';
import '../../domain/entities/project_type.dart';
import '../../domain/exceptions/client_exception.dart';
import '../widgets/project_badges.dart';
import '../widgets/quick_add_client_dialog.dart';

/// Admin Staff (admin and cleaning staff) never work on client projects, so
/// that department and its employees aren't offered when assigning a project
/// — unless one is already on the project being edited, so nothing is
/// silently dropped.
bool _isAdminStaff(String? departmentName) =>
    departmentName?.trim().toLowerCase() == 'admin staff';

/// Only people still working for the company can be assigned (active, on
/// leave, or serving their notice) — not resigned or terminated ones.
bool _isStillWorking(String employmentStatus) =>
    employmentStatus == 'active' ||
    employmentStatus == 'on_leave' ||
    employmentStatus == 'notice_period';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Create or edit a project: client (searchable, with a quick "add new"),
/// type/status, a start date plus the date that fits the type (a one-time
/// project's deadline, or a monthly retainer's renewal date), department and
/// employee assignment, and the account manager / project owner.
/// Departments are picked first and directly rather than derived from the
/// assigned employees — a project regularly involves people from a
/// department who aren't individually assigned to it yet, or spans several
/// teams working together (a "Hybrid" project, shown once more than one is
/// picked). Employees are then found with a search box.
class ProjectEditorPage extends ConsumerStatefulWidget {
  const ProjectEditorPage({
    super.key,
    this.existingProject,
    this.initialClientId,
  });

  /// Null when creating a new project; the current project when editing.
  final Project? existingProject;

  /// Pre-selects the client when starting a project from that client's page.
  final String? initialClientId;

  @override
  ConsumerState<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends ConsumerState<ProjectEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  String? _clientId;
  late String _type;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _renewalDate;
  late Set<String> _selectedEmployeeIds;
  late Set<String> _selectedDepartmentIds;
  String? _accountManagerId;

  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProject;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _clientId = existing?.clientId ?? widget.initialClientId;
    _type = existing?.type ?? ProjectType.oneTime;
    _status = existing?.status ?? ProjectStatus.active;
    _startDate = existing != null ? DateTime.parse(existing.startDate) : null;
    _endDate = existing?.endDate != null
        ? DateTime.parse(existing!.endDate!)
        : null;
    _renewalDate = existing?.renewalDate != null
        ? DateTime.parse(existing!.renewalDate!)
        : null;
    _selectedEmployeeIds = {
      ...(existing?.assignedEmployees.map((e) => e.id) ?? const []),
    };
    _accountManagerId = existing?.accountManager?.id;
    _selectedDepartmentIds = {
      ...(existing?.targetDepartments.map((d) => d.id) ?? const []),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) {
      setState(() => _errorMessage = 'Select a client.');
      return;
    }
    if (_startDate == null) {
      setState(() => _errorMessage = 'Select a start date.');
      return;
    }
    final isRetainer = _type == ProjectType.retainer;
    if (isRetainer && _renewalDate == null) {
      setState(() => _errorMessage = 'Set a renewal date.');
      return;
    }
    if (!isRetainer && _endDate == null) {
      setState(() => _errorMessage = 'Set a deadline.');
      return;
    }
    if (!isRetainer && _endDate!.isBefore(_startDate!)) {
      setState(
        () => _errorMessage = 'The deadline can\'t be before the start date.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final departmentIds = _selectedDepartmentIds.toList();

    final repository = ref.read(clientsRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateProject(
              widget.existingProject!.id,
              clientId: _clientId,
              name: _nameController.text.trim(),
              type: _type,
              status: _status,
              startDate: _isoDate(_startDate!),
              endDate: !isRetainer ? _isoDate(_endDate!) : null,
              renewalDate: isRetainer ? _isoDate(_renewalDate!) : null,
              notes: _notesController.text.trim(),
              assignedEmployeeIds: _selectedEmployeeIds.toList(),
              // An empty id clears the manager.
              accountManagerId: _accountManagerId ?? '',
              targetDepartmentIds: departmentIds,
            )
          : await repository.createProject(
              clientId: _clientId!,
              name: _nameController.text.trim(),
              type: _type,
              status: _status,
              startDate: _isoDate(_startDate!),
              endDate: !isRetainer ? _isoDate(_endDate!) : null,
              renewalDate: isRetainer ? _isoDate(_renewalDate!) : null,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              assignedEmployeeIds: _selectedEmployeeIds.toList(),
              accountManagerId: _accountManagerId,
              targetDepartmentIds: departmentIds,
            );

      for (final includeArchived in [false, true]) {
        ref.invalidate(
          projectsListProvider((
            status: null,
            clientId: null,
            includeArchived: includeArchived,
          )),
        );
        ref.invalidate(
          projectsListProvider((
            status: null,
            clientId: saved.clientId,
            includeArchived: includeArchived,
          )),
        );
      }
      ref.invalidate(projectProvider(saved.id));
      ref.invalidate(projectsSummaryProvider);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ClientException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider(false));
    final employeesAsync = ref.watch(employeeListProvider);
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Project' : 'New Project')),
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
                    clientsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Could not load clients.'),
                      data: (clients) => _ClientSearchField(
                        clients: clients,
                        selectedClientId: _clientId,
                        enabled: !_submitting,
                        onSelected: (client) =>
                            setState(() => _clientId = client.id),
                        onAddNew: (query) async {
                          final created = await showQuickAddClientDialog(
                            context,
                            ref,
                            initialName: query,
                          );
                          if (created == null) return null;
                          ref.invalidate(clientsListProvider(false));
                          setState(() => _clientId = created.id);
                          return created;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().length < 2)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                            items: [
                              for (final type in ProjectType.values)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(formatProjectTypeLabel(type)),
                                ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _type = value);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: [
                              for (final status in ProjectStatus.values)
                                DropdownMenuItem(
                                  value: status,
                                  child: Text(formatProjectStatusLabel(status)),
                                ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _status = value);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      key: const Key('project-start-date'),
                      label: 'Start date',
                      value: _startDate,
                      onTap: () => _pickDate(
                        current: _startDate,
                        onPicked: (d) => setState(() => _startDate = d),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // A one-time project has a deadline; a monthly retainer
                    // has a renewal date — only the one that fits is shown.
                    if (_type == ProjectType.retainer)
                      _DateField(
                        key: const Key('project-renewal-date'),
                        label: 'Renewal date',
                        value: _renewalDate,
                        onTap: () => _pickDate(
                          current: _renewalDate,
                          onPicked: (d) => setState(() => _renewalDate = d),
                        ),
                      )
                    else
                      _DateField(
                        key: const Key('project-deadline'),
                        label: 'Deadline',
                        value: _endDate,
                        onTap: () => _pickDate(
                          current: _endDate,
                          onPicked: (d) => setState(() => _endDate = d),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Project details',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Departments',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (_selectedDepartmentIds.length > 1) ...[
                          const SizedBox(width: 8),
                          const HybridBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick more than one when several teams are working on '
                      'this project together.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    departmentsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) =>
                          const Text('Could not load departments.'),
                      data: (departments) => _ChipMultiSelect<Department>(
                        items: [
                          for (final d in departments)
                            if (!_isAdminStaff(d.name) ||
                                _selectedDepartmentIds.contains(d.id))
                              d,
                        ],
                        idOf: (d) => d.id,
                        labelOf: (d) => d.name,
                        selectedIds: _selectedDepartmentIds,
                        onToggled: (id, selected) => setState(() {
                          if (selected) {
                            _selectedDepartmentIds.add(id);
                          } else {
                            _selectedDepartmentIds.remove(id);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Assigned employees',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    employeesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Could not load employees.'),
                      data: (employees) => _EmployeeSearchPicker(
                        employees: [
                          for (final e in employees)
                            if (_selectedEmployeeIds.contains(e.id) ||
                                (!_isAdminStaff(e.department?.name) &&
                                    _isStillWorking(e.employmentStatus)))
                              e,
                        ],
                        selectedIds: _selectedEmployeeIds,
                        enabled: !_submitting,
                        onAdded: (id) =>
                            setState(() => _selectedEmployeeIds.add(id)),
                        onRemoved: (id) => setState(() {
                          _selectedEmployeeIds.remove(id);
                          if (_accountManagerId == id) _accountManagerId = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // The owner is picked from the people assigned above.
                    employeesAsync.maybeWhen(
                      data: (employees) {
                        final assigned = [
                          for (final e in employees)
                            if (_selectedEmployeeIds.contains(e.id)) e,
                        ];
                        return DropdownButtonFormField<String>(
                          key: const Key('project-account-manager'),
                          initialValue: _accountManagerId,
                          decoration: InputDecoration(
                            labelText: 'Account manager / project owner',
                            helperText: assigned.isEmpty
                                ? 'Assign employees first, then pick the owner '
                                      'from them.'
                                : null,
                          ),
                          items: [
                            for (final e in assigned)
                              DropdownMenuItem(
                                value: e.id,
                                child: Text(e.fullName),
                              ),
                          ],
                          onChanged: _submitting || assigned.isEmpty
                              ? null
                              : (value) =>
                                    setState(() => _accountManagerId = value),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
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
                        : Text(_isEditing ? 'Save changes' : 'Create Project'),
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

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value == null ? '—' : formatDisplayDate(_isoDate(value!))),
      ),
    );
  }
}

class _ChipMultiSelect<T> extends StatelessWidget {
  const _ChipMultiSelect({
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.selectedIds,
    required this.onToggled,
  });

  final List<T> items;
  final String Function(T) idOf;
  final String Function(T) labelOf;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggled;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          FilterChip(
            label: Text(labelOf(item)),
            selected: selectedIds.contains(idOf(item)),
            onSelected: (selected) => onToggled(idOf(item), selected),
          ),
      ],
    );
  }
}

/// Search-as-you-type multi-select for employees: type to find someone, tap
/// a match to add them, and the chosen people show as removable chips.
class _EmployeeSearchPicker extends StatelessWidget {
  const _EmployeeSearchPicker({
    required this.employees,
    required this.selectedIds,
    required this.enabled,
    required this.onAdded,
    required this.onRemoved,
  });

  final List<Employee> employees;
  final Set<String> selectedIds;
  final bool enabled;
  final ValueChanged<String> onAdded;
  final ValueChanged<String> onRemoved;

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final e in employees)
        if (selectedIds.contains(e.id)) e,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Employee>(
          displayStringForOption: (e) => e.fullName,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return const Iterable<Employee>.empty();
            return employees.where(
              (e) =>
                  !selectedIds.contains(e.id) &&
                  e.fullName.toLowerCase().contains(query),
            );
          },
          onSelected: (e) => onAdded(e.id),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              decoration: const InputDecoration(
                hintText: 'Search employees by name',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onSubmitted: (_) => onSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 420,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final e in options)
                      ListTile(
                        dense: true,
                        title: Text(e.fullName),
                        onTap: () => onSelected(e),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in selected)
                InputChip(
                  label: Text(e.fullName),
                  onDeleted: enabled ? () => onRemoved(e.id) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One row in the client picker: a client, or (null) the "+ Add new" row.
class _ClientOption {
  const _ClientOption(this.client);

  final Client? client;
}

/// Type-ahead client picker. Matches show as you type; when nothing matches,
/// a "+ Add" row offers to create the client on the spot (and a button below
/// is always there too).
class _ClientSearchField extends StatefulWidget {
  const _ClientSearchField({
    required this.clients,
    required this.selectedClientId,
    required this.enabled,
    required this.onSelected,
    required this.onAddNew,
  });

  final List<Client> clients;
  final String? selectedClientId;
  final bool enabled;
  final ValueChanged<Client> onSelected;

  /// Opens the "new client" flow pre-filled with [query]; returns the created
  /// client, or null if cancelled.
  final Future<Client?> Function(String query) onAddNew;

  @override
  State<_ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<_ClientSearchField> {
  TextEditingController? _controller;
  String _lastQuery = '';

  String get _selectedName {
    for (final client in widget.clients) {
      if (client.id == widget.selectedClientId) return client.companyName;
    }
    return '';
  }

  Future<void> _addNew([String? query]) async {
    final created = await widget.onAddNew((query ?? _lastQuery).trim());
    if (created != null) _controller?.text = created.companyName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<_ClientOption>(
          initialValue: TextEditingValue(text: _selectedName),
          displayStringForOption: (option) => option.client?.companyName ?? '',
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            _lastQuery = value.text;
            if (!widget.enabled) return const Iterable<_ClientOption>.empty();
            final matches = query.isEmpty
                ? widget.clients
                : widget.clients.where(
                    (c) => c.companyName.toLowerCase().contains(query),
                  );
            return [
              for (final client in matches) _ClientOption(client),
              if (query.isNotEmpty && matches.isEmpty)
                const _ClientOption(null),
            ];
          },
          onSelected: (option) {
            final client = option.client;
            if (client == null) {
              _addNew();
            } else {
              widget.onSelected(client);
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            _controller = controller;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              decoration: const InputDecoration(
                labelText: 'Client',
                hintText: 'Search clients',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              validator: (_) =>
                  widget.selectedClientId == null ? 'Required' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 240,
                  maxWidth: 420,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      if (option.client == null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add, size: 18),
                          title: Text(
                            _lastQuery.trim().isEmpty
                                ? 'Add a new client'
                                : 'Add "${_lastQuery.trim()}" as a new client',
                          ),
                          onTap: () => onSelected(option),
                        )
                      else
                        ListTile(
                          dense: true,
                          title: Text(option.client!.companyName),
                          onTap: () => onSelected(option),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.enabled ? () => _addNew() : null,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Can't find your client? Add new"),
          ),
        ),
      ],
    );
  }
}
