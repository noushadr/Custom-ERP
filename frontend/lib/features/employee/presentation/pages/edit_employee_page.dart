import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/edit_employee_controller.dart';
import '../../application/edit_employee_state.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/update_employee_input.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';

const _employmentTypes = {
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract': 'Contract',
  'intern': 'Intern',
};

const _employmentStatuses = {
  'active': 'Active',
  'on_leave': 'On Leave',
  'notice_period': 'Notice Period',
  'resigned': 'Resigned',
  'terminated': 'Terminated',
};

const _workModes = {
  'on_site': 'On-site',
  'remote': 'Remote',
  'hybrid': 'Hybrid',
};

/// HR/Admin-facing edit form — reachable when the viewer has
/// `employees.manage` and is editing someone other than themselves.
/// Exposes organizational fields (department, manager, employment
/// status, ...) in addition to everything the self-service edit allows.
class EditEmployeePage extends ConsumerStatefulWidget {
  const EditEmployeePage({super.key, required this.employee});

  final Employee employee;

  @override
  ConsumerState<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends ConsumerState<EditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _designationController;
  late final TextEditingController _personalEmailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountTitleController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _branchCodeController;
  late final TextEditingController _ibanController;
  String? _departmentId;
  String? _teamId;
  String? _reportingManagerId;
  late String _employmentType;
  late String _employmentStatus;
  late String _workMode;
  late DateTime _joiningDate;
  DateTime? _dateOfLeaving;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _firstNameController = TextEditingController(text: e.firstName);
    _lastNameController = TextEditingController(text: e.lastName);
    _designationController = TextEditingController(text: e.designation);
    _personalEmailController = TextEditingController(text: e.personalEmail);
    _phoneController = TextEditingController(text: e.phoneNumber);
    _addressController = TextEditingController(text: e.address);
    _emergencyNameController = TextEditingController(
      text: e.emergencyContactName,
    );
    _emergencyPhoneController = TextEditingController(
      text: e.emergencyContactPhone,
    );
    _emergencyRelationController = TextEditingController(
      text: e.emergencyContactRelation,
    );
    _bankNameController = TextEditingController(text: e.bankName);
    _accountTitleController = TextEditingController(text: e.accountTitle);
    _accountNumberController = TextEditingController(text: e.accountNumber);
    _branchCodeController = TextEditingController(text: e.branchCode);
    _ibanController = TextEditingController(text: e.iban);
    _departmentId = e.department?.id;
    _teamId = e.team?.id;
    _reportingManagerId = e.reportingManager?.id;
    _employmentType = e.employmentType;
    _employmentStatus = e.employmentStatus;
    _workMode = e.workMode;
    _joiningDate = DateTime.parse(e.joiningDate);
    _dateOfLeaving = e.dateOfLeaving == null
        ? null
        : DateTime.tryParse(e.dateOfLeaving!);
    _dateOfBirth = e.dateOfBirth == null
        ? null
        : DateTime.tryParse(e.dateOfBirth!);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _designationController.dispose();
    _personalEmailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _branchCodeController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(editEmployeeControllerProvider.notifier)
        .submit(
          widget.employee.id,
          UpdateEmployeeInput(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            designation: _designationController.text.trim().isEmpty
                ? null
                : _designationController.text.trim(),
            departmentId: _departmentId,
            teamId: _teamId,
            reportingManagerId: _reportingManagerId,
            employmentType: _employmentType,
            employmentStatus: _employmentStatus,
            workMode: _workMode,
            joiningDate: _isoDate(_joiningDate),
            dateOfLeaving: _dateOfLeaving == null
                ? null
                : _isoDate(_dateOfLeaving!),
            personalEmail: _personalEmailController.text.trim().isEmpty
                ? null
                : _personalEmailController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            dateOfBirth: _dateOfBirth == null
                ? null
                : _isoDate(_dateOfBirth!),
            emergencyContactName: _emergencyNameController.text.trim().isEmpty
                ? null
                : _emergencyNameController.text.trim(),
            emergencyContactPhone:
                _emergencyPhoneController.text.trim().isEmpty
                ? null
                : _emergencyPhoneController.text.trim(),
            emergencyContactRelation:
                _emergencyRelationController.text.trim().isEmpty
                ? null
                : _emergencyRelationController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            bankName: _bankNameController.text.trim().isEmpty
                ? null
                : _bankNameController.text.trim(),
            accountTitle: _accountTitleController.text.trim().isEmpty
                ? null
                : _accountTitleController.text.trim(),
            accountNumber: _accountNumberController.text.trim().isEmpty
                ? null
                : _accountNumberController.text.trim(),
            branchCode: _branchCodeController.text.trim().isEmpty
                ? null
                : _branchCodeController.text.trim(),
            iban: _ibanController.text.trim().isEmpty
                ? null
                : _ibanController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditEmployeeState>(editEmployeeControllerProvider, (
      previous,
      next,
    ) {
      if (next is EditEmployeeSuccess) {
        ref.invalidate(employeeListProvider);
        ref.invalidate(employeeDetailProvider(widget.employee.id));
        ref.invalidate(employeeAuditLogProvider(widget.employee.id));
        Navigator.of(context).pop();
      } else if (next is EditEmployeeError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final state = ref.watch(editEmployeeControllerProvider);
    final isSubmitting = state is EditEmployeeSubmitting;
    final departmentsAsync = ref.watch(departmentsProvider);
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.employee.fullName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    title: 'Identity',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'First name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Last name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _designationController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Designation',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Organization',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        departmentsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) =>
                              const Text('Could not load departments.'),
                          data: (departments) => DropdownButtonFormField<String>(
                            initialValue: _departmentId,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                            ),
                            items: [
                              for (final d in departments)
                                DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name),
                                ),
                            ],
                            onChanged: isSubmitting
                                ? null
                                : (value) => setState(() {
                                    _departmentId = value;
                                    _teamId = null;
                                  }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final teamsAsync = ref.watch(
                              teamsProvider(_departmentId),
                            );
                            return teamsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) =>
                                  const Text('Could not load teams.'),
                              data: (teams) => DropdownButtonFormField<String>(
                                initialValue: teams.any((t) => t.id == _teamId)
                                    ? _teamId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Team',
                                ),
                                items: [
                                  for (final t in teams)
                                    DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ),
                                ],
                                onChanged: isSubmitting
                                    ? null
                                    : (value) =>
                                        setState(() => _teamId = value),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        employeesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) =>
                              const Text('Could not load employees.'),
                          data: (employees) {
                            final candidates = employees
                                .where((e) => e.id != widget.employee.id)
                                .toList();
                            final validValue =
                                candidates.any((e) => e.id == _reportingManagerId)
                                ? _reportingManagerId
                                : null;
                            return DropdownButtonFormField<String?>(
                              initialValue: validValue,
                              decoration: const InputDecoration(
                                labelText: 'Reporting manager',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                for (final e in candidates)
                                  DropdownMenuItem<String?>(
                                    value: e.id,
                                    child: Text(e.fullName),
                                  ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (value) => setState(
                                      () => _reportingManagerId = value,
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _employmentType,
                          decoration: const InputDecoration(
                            labelText: 'Employment type',
                          ),
                          items: [
                            for (final entry in _employmentTypes.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) =>
                                  setState(() => _employmentType = value!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _employmentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Employment status',
                          ),
                          items: [
                            for (final entry in _employmentStatuses.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) =>
                                  setState(() => _employmentStatus = value!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _workMode,
                          decoration: const InputDecoration(
                            labelText: 'Work mode',
                          ),
                          items: [
                            for (final entry in _workModes.entries)
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) => setState(() => _workMode = value!),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () => _pickDate(
                                  initial: _joiningDate,
                                  onPicked: (d) =>
                                      setState(() => _joiningDate = d!),
                                ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Joining date',
                            ),
                            child: Text(
                              formatDisplayDate(_isoDate(_joiningDate)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () => _pickDate(
                                        initial: _dateOfLeaving,
                                        onPicked: (d) => setState(
                                          () => _dateOfLeaving = d,
                                        ),
                                      ),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of leaving',
                                  ),
                                  child: Text(
                                    _dateOfLeaving == null
                                        ? '—'
                                        : formatDisplayDate(
                                            _isoDate(_dateOfLeaving!),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            if (_dateOfLeaving != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Clear',
                                onPressed: isSubmitting
                                    ? null
                                    : () =>
                                        setState(() => _dateOfLeaving = null),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _personalEmailController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Personal email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final emailRegExp = RegExp(
                              r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
                            );
                            return emailRegExp.hasMatch(value.trim())
                                ? null
                                : 'Enter a valid email address';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () => _pickDate(
                                  initial: _dateOfBirth,
                                  onPicked: (d) =>
                                      setState(() => _dateOfBirth = d),
                                ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of birth',
                            ),
                            child: Text(
                              _dateOfBirth == null
                                  ? '—'
                                  : formatDisplayDate(_isoDate(_dateOfBirth!)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Bank Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _bankNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Bank name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountTitleController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Account title',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _accountNumberController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Account number',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _branchCodeController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Branch code',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ibanController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'IBAN',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormSection(
                    title: 'Emergency contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emergencyNameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyRelationController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Relation',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
