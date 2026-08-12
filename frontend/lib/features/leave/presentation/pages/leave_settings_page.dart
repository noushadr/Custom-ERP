import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/application/employee_providers.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/exceptions/leave_exception.dart';
import '../utils/leave_format_utils.dart';

/// Lets Super Admin/HR-Manager configure leave types and their policies,
/// and manually adjust any employee's leave balance. Requires `leave.manage`.
class LeaveSettingsPage extends ConsumerStatefulWidget {
  const LeaveSettingsPage({super.key});

  @override
  ConsumerState<LeaveSettingsPage> createState() => _LeaveSettingsPageState();
}

class _LeaveSettingsPageState extends ConsumerState<LeaveSettingsPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final leaveTypesAsync = ref.watch(leaveTypesProvider(_includeArchived));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Settings'),
        actions: [
          IconButton(
            tooltip: 'Add leave type',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _LeaveTypeFormDialog(leaveType: null),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Leave Types',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
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
                const SizedBox(height: 8),
                leaveTypesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) =>
                      const Text('Could not load leave types. Please try again.'),
                  data: (leaveTypes) {
                    if (leaveTypes.isEmpty) {
                      return const Text('No leave types yet.');
                    }
                    return Column(
                      children: [
                        for (final type in leaveTypes) ...[
                          _LeaveTypeCard(leaveType: type),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _AdjustBalanceSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveTypeCard extends ConsumerWidget {
  const _LeaveTypeCard({required this.leaveType});

  final LeaveType leaveType;

  Future<void> _setArchived(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref
          .read(leaveRepositoryProvider)
          .updateLeaveType(leaveType.id, isArchived: value);
      ref.invalidate(leaveTypesProvider);
    } on LeaveException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseLeaveColor(leaveType.colorHex) ?? AppColors.primary;
    return FormSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      leaveType.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (leaveType.isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Archived',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatLeaveDays(leaveType.annualAllowanceDays)} day(s) / year'
                  '${leaveType.carryForwardLimitDays != null ? ' · up to ${formatLeaveDays(leaveType.carryForwardLimitDays!)} day(s) carry forward' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _LeaveTypeFormDialog(leaveType: leaveType),
            ),
          ),
          TextButton(
            onPressed: () => _setArchived(context, ref, !leaveType.isArchived),
            child: Text(leaveType.isArchived ? 'Unarchive' : 'Archive'),
          ),
        ],
      ),
    );
  }
}

class _LeaveTypeFormDialog extends ConsumerStatefulWidget {
  const _LeaveTypeFormDialog({required this.leaveType});

  final LeaveType? leaveType;

  @override
  ConsumerState<_LeaveTypeFormDialog> createState() =>
      _LeaveTypeFormDialogState();
}

class _LeaveTypeFormDialogState extends ConsumerState<_LeaveTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _allowanceController;
  late final TextEditingController _carryForwardController;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.leaveType != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.leaveType?.name);
    _allowanceController = TextEditingController(
      text: widget.leaveType == null
          ? null
          : formatLeaveDays(widget.leaveType!.annualAllowanceDays),
    );
    _carryForwardController = TextEditingController(
      text: widget.leaveType?.carryForwardLimitDays == null
          ? null
          : formatLeaveDays(widget.leaveType!.carryForwardLimitDays!),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();
    _carryForwardController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(leaveRepositoryProvider);
      final name = _nameController.text.trim();
      final allowance = double.parse(_allowanceController.text.trim());
      final carryForwardText = _carryForwardController.text.trim();
      final carryForward = carryForwardText.isEmpty
          ? null
          : double.parse(carryForwardText);

      if (_isEditing) {
        await repository.updateLeaveType(
          widget.leaveType!.id,
          name: name,
          annualAllowanceDays: allowance,
          carryForwardLimitDays: carryForward,
        );
      } else {
        await repository.createLeaveType(
          name: name,
          annualAllowanceDays: allowance,
          carryForwardLimitDays: carryForward,
        );
      }
      ref.invalidate(leaveTypesProvider);
      if (mounted) Navigator.of(context).pop();
    } on LeaveException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit leave type' : 'Add leave type'),
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
                controller: _allowanceController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Annual allowance (days)',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  return (parsed == null || parsed < 0) ? 'Enter a valid number' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carryForwardController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Carry-forward limit (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return double.tryParse(value.trim()) == null
                      ? 'Enter a valid number'
                      : null;
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
              : Text(_isEditing ? 'Save changes' : 'Add leave type'),
        ),
      ],
    );
  }
}

class _AdjustBalanceSection extends StatelessWidget {
  const _AdjustBalanceSection();

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: "Adjust an Employee's Balance",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grant or deduct leave days for a specific employee, leave type, '
            'and year — e.g. a one-off bonus day or a correction.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _AdjustBalanceDialog(),
              ),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Adjust a balance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustBalanceDialog extends ConsumerStatefulWidget {
  const _AdjustBalanceDialog();

  @override
  ConsumerState<_AdjustBalanceDialog> createState() =>
      _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends ConsumerState<_AdjustBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deltaController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _employeeId;
  String? _leaveTypeId;
  int _year = DateTime.now().year;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _deltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null || _leaveTypeId == null) {
      setState(() => _errorMessage = 'Please choose an employee and a leave type.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(leaveRepositoryProvider)
          .adjustBalance(
            _employeeId!,
            leaveTypeId: _leaveTypeId!,
            year: _year,
            deltaDays: double.parse(_deltaController.text.trim()),
            reason: _reasonController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on LeaveException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider);
    final leaveTypesAsync = ref.watch(leaveTypesProvider(false));

    return AlertDialog(
      title: const Text('Adjust a balance'),
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
              employeesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load employees.'),
                data: (employees) => DropdownButtonFormField<String>(
                  initialValue: _employeeId,
                  decoration: const InputDecoration(labelText: 'Employee'),
                  items: [
                    for (final employee in employees)
                      DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.fullName),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _employeeId = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              leaveTypesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load leave types.'),
                data: (leaveTypes) => DropdownButtonFormField<String>(
                  initialValue: _leaveTypeId,
                  decoration: const InputDecoration(labelText: 'Leave type'),
                  items: [
                    for (final type in leaveTypes)
                      DropdownMenuItem(value: type.id, child: Text(type.name)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _leaveTypeId = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _year.toString(),
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (value) =>
                          _year = int.tryParse(value) ?? _year,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _deltaController,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Delta (+/- days)',
                      ),
                      validator: (value) =>
                          double.tryParse(value?.trim() ?? '') == null
                          ? 'Enter a number'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                enabled: !_saving,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
