import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_status.dart';
import '../../domain/entities/project_type.dart';
import '../../domain/entities/service.dart';
import '../../domain/exceptions/client_exception.dart';
import '../widgets/project_badges.dart';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Create or edit a project: client, type/status, dates, SEO
/// package/tracking details, and employee/department/service assignment.
class ProjectEditorPage extends ConsumerStatefulWidget {
  const ProjectEditorPage({super.key, this.existingProject});

  /// Null when creating a new project; the current project when editing.
  final Project? existingProject;

  @override
  ConsumerState<ProjectEditorPage> createState() => _ProjectEditorPageState();
}

class _ProjectEditorPageState extends ConsumerState<ProjectEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late final TextEditingController _packageNameController;
  late final TextEditingController _backlinksTargetController;
  late final TextEditingController _seoSheetNameController;
  late final TextEditingController _projectFolderNameController;
  late final TextEditingController _workingEmailAccountController;
  late final TextEditingController _ahrefsAccountController;

  String? _clientId;
  late String _type;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _renewalDate;
  late Set<String> _selectedEmployeeIds;
  late Set<String> _selectedDepartmentIds;
  late Set<String> _selectedServiceIds;

  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProject;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _packageNameController = TextEditingController(
      text: existing?.packageName ?? '',
    );
    _backlinksTargetController = TextEditingController(
      text: existing?.backlinksTarget ?? '',
    );
    _seoSheetNameController = TextEditingController(
      text: existing?.seoSheetName ?? '',
    );
    _projectFolderNameController = TextEditingController(
      text: existing?.projectFolderName ?? '',
    );
    _workingEmailAccountController = TextEditingController(
      text: existing?.workingEmailAccount ?? '',
    );
    _ahrefsAccountController = TextEditingController(
      text: existing?.ahrefsAccount ?? '',
    );
    _clientId = existing?.clientId;
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
    _selectedDepartmentIds = {
      ...(existing?.targetDepartments.map((d) => d.id) ?? const []),
    };
    _selectedServiceIds = {
      ...(existing?.services.map((s) => s.id) ?? const []),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _packageNameController.dispose();
    _backlinksTargetController.dispose();
    _seoSheetNameController.dispose();
    _projectFolderNameController.dispose();
    _workingEmailAccountController.dispose();
    _ahrefsAccountController.dispose();
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

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

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
              endDate: _endDate != null ? _isoDate(_endDate!) : null,
              renewalDate: _renewalDate != null ? _isoDate(_renewalDate!) : null,
              notes: _notesController.text.trim(),
              packageName: _packageNameController.text.trim(),
              backlinksTarget: _backlinksTargetController.text.trim(),
              seoSheetName: _seoSheetNameController.text.trim(),
              projectFolderName: _projectFolderNameController.text.trim(),
              workingEmailAccount: _workingEmailAccountController.text.trim(),
              ahrefsAccount: _ahrefsAccountController.text.trim(),
              assignedEmployeeIds: _selectedEmployeeIds.toList(),
              targetDepartmentIds: _selectedDepartmentIds.toList(),
              serviceIds: _selectedServiceIds.toList(),
            )
          : await repository.createProject(
              clientId: _clientId!,
              name: _nameController.text.trim(),
              type: _type,
              status: _status,
              startDate: _isoDate(_startDate!),
              endDate: _endDate != null ? _isoDate(_endDate!) : null,
              renewalDate: _renewalDate != null ? _isoDate(_renewalDate!) : null,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              packageName: _emptyToNull(_packageNameController.text),
              backlinksTarget: _emptyToNull(_backlinksTargetController.text),
              seoSheetName: _emptyToNull(_seoSheetNameController.text),
              projectFolderName: _emptyToNull(
                _projectFolderNameController.text,
              ),
              workingEmailAccount: _emptyToNull(
                _workingEmailAccountController.text,
              ),
              ahrefsAccount: _emptyToNull(_ahrefsAccountController.text),
              assignedEmployeeIds: _selectedEmployeeIds.toList(),
              targetDepartmentIds: _selectedDepartmentIds.toList(),
              serviceIds: _selectedServiceIds.toList(),
            );

      ref.invalidate(projectsListProvider((status: null, clientId: null)));
      ref.invalidate(
        projectsListProvider((status: null, clientId: saved.clientId)),
      );
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

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsListProvider(false));
    final employeesAsync = ref.watch(employeeListProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final servicesAsync = ref.watch(servicesListProvider(false));

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
                      data: (clients) => DropdownButtonFormField<String>(
                        initialValue: _clientId,
                        decoration: const InputDecoration(labelText: 'Client'),
                        items: [
                          for (final Client client in clients)
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(client.companyName),
                            ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _clientId = value),
                        validator: (value) =>
                            value == null ? 'Required' : null,
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
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            key: const Key('project-start-date'),
                            label: 'Start date',
                            value: _startDate,
                            onTap: () => _pickDate(
                              current: _startDate,
                              onPicked: (d) => setState(() => _startDate = d),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'End date',
                            value: _endDate,
                            onTap: () => _pickDate(
                              current: _endDate,
                              onPicked: (d) => setState(() => _endDate = d),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      label: 'Renewal date',
                      value: _renewalDate,
                      onTap: () => _pickDate(
                        current: _renewalDate,
                        onPicked: (d) => setState(() => _renewalDate = d),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _packageNameController,
                            decoration: const InputDecoration(
                              labelText: 'Package',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _backlinksTargetController,
                            decoration: const InputDecoration(
                              labelText: 'Backlinks target',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _seoSheetNameController,
                            decoration: const InputDecoration(
                              labelText: 'SEO sheet name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _projectFolderNameController,
                            decoration: const InputDecoration(
                              labelText: 'Project folder name',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _workingEmailAccountController,
                            decoration: const InputDecoration(
                              labelText: 'Working email account',
                              helperText:
                                  'Reference only — no passwords stored here.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _ahrefsAccountController,
                            decoration: const InputDecoration(
                              labelText: 'Ahrefs account',
                              helperText:
                                  'Reference only — no passwords stored here.',
                            ),
                          ),
                        ),
                      ],
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
                      data: (employees) => _ChipMultiSelect<Employee>(
                        items: employees,
                        idOf: (e) => e.id,
                        labelOf: (e) => e.fullName,
                        selectedIds: _selectedEmployeeIds,
                        onToggled: (id, selected) => setState(() {
                          if (selected) {
                            _selectedEmployeeIds.add(id);
                          } else {
                            _selectedEmployeeIds.remove(id);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Teams (departments)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    departmentsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) =>
                          const Text('Could not load departments.'),
                      data: (departments) => _ChipMultiSelect<Department>(
                        items: departments,
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
                    const SizedBox(height: 16),
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    servicesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Could not load services.'),
                      data: (services) => _ChipMultiSelect<Service>(
                        items: services,
                        idOf: (s) => s.id,
                        labelOf: (s) => s.name,
                        selectedIds: _selectedServiceIds,
                        onToggled: (id, selected) => setState(() {
                          if (selected) {
                            _selectedServiceIds.add(id);
                          } else {
                            _selectedServiceIds.remove(id);
                          }
                        }),
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
        child: Text(value == null ? '—' : _isoDate(value!)),
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
