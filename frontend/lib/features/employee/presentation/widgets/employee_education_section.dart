import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/education_record.dart';
import '../../domain/exceptions/employee_exception.dart';

/// Lists degrees earned, with an "Add degree" action and per-record delete.
/// Pass null for [employeeId] to manage the current user's own education
/// history; pass an id (requires `employees.manage`) to manage another
/// employee's.
class EmployeeEducationSection extends ConsumerStatefulWidget {
  const EmployeeEducationSection({super.key, this.employeeId});

  final String? employeeId;

  @override
  ConsumerState<EmployeeEducationSection> createState() =>
      _EmployeeEducationSectionState();
}

class _EmployeeEducationSectionState
    extends ConsumerState<EmployeeEducationSection> {
  String? _deletingRecordId;

  bool get _isSelf => widget.employeeId == null;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _invalidate() {
    if (_isSelf) {
      ref.invalidate(myEducationHistoryProvider);
      ref.invalidate(myAuditLogProvider);
    } else {
      ref.invalidate(employeeEducationHistoryProvider(widget.employeeId!));
      ref.invalidate(employeeAuditLogProvider(widget.employeeId!));
    }
  }

  Future<void> _addDegree() async {
    final result = await showDialog<_AddEducationResult>(
      context: context,
      builder: (_) => const _AddEducationDialog(),
    );
    if (result == null) return;

    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.addMyEducationRecord(
          degree: result.degree,
          institution: result.institution,
          yearCompleted: result.yearCompleted,
        );
      } else {
        await repository.addEducationRecord(
          widget.employeeId!,
          degree: result.degree,
          institution: result.institution,
          yearCompleted: result.yearCompleted,
        );
      }
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _delete(EducationRecord record) async {
    setState(() => _deletingRecordId = record.id);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.deleteMyEducationRecord(record.id);
      } else {
        await repository.deleteEducationRecord(widget.employeeId!, record.id);
      }
      _invalidate();
    } on EmployeeException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _deletingRecordId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = _isSelf
        ? ref.watch(myEducationHistoryProvider)
        : ref.watch(employeeEducationHistoryProvider(widget.employeeId!));

    return FormSection(
      title: 'Education',
      child: historyAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load education history.'),
        data: (records) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (records.isEmpty)
                Text(
                  'No education records yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (var i = 0; i < records.length; i++) ...[
                  _EducationRow(
                    record: records[i],
                    isDeleting: _deletingRecordId == records[i].id,
                    onDelete: () => _delete(records[i]),
                  ),
                  if (i < records.length - 1)
                    const Divider(height: 20, color: AppColors.borderSubtle),
                ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addDegree,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add degree'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EducationRow extends StatelessWidget {
  const _EducationRow({
    required this.record,
    required this.isDeleting,
    required this.onDelete,
  });

  final EducationRecord record;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.degree,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.institution} · ${record.yearCompleted}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                  onPressed: onDelete,
                ),
        ],
      ),
    );
  }
}

class _AddEducationResult {
  const _AddEducationResult({
    required this.degree,
    required this.institution,
    required this.yearCompleted,
  });

  final String degree;
  final String institution;
  final int yearCompleted;
}

class _AddEducationDialog extends StatefulWidget {
  const _AddEducationDialog();

  @override
  State<_AddEducationDialog> createState() => _AddEducationDialogState();
}

class _AddEducationDialogState extends State<_AddEducationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _AddEducationResult(
        degree: _degreeController.text.trim(),
        institution: _institutionController.text.trim(),
        yearCompleted: int.parse(_yearController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add degree'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a degree'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: 'University'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a university'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year passed'),
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed < 1950 || parsed > 2100) {
                  return 'Enter a valid year';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
