import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/tag_input.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/update_my_profile_input.dart';
import '../../domain/exceptions/employee_exception.dart';

enum EmployeeTagsField { skills, certifications }

/// An inline, always-editable Skills or Certifications list on the profile
/// page itself — same idea as [EmployeeEducationSection]: no separate edit
/// page, changes save immediately. Pass null for [employeeId] to manage the
/// current user's own list; pass an id (requires `employees.manage`) to
/// manage another employee's.
class EmployeeTagsSection extends ConsumerStatefulWidget {
  const EmployeeTagsSection({
    super.key,
    required this.title,
    required this.values,
    required this.field,
    this.employeeId,
  });

  final String title;
  final List<String> values;
  final EmployeeTagsField field;
  final String? employeeId;

  @override
  ConsumerState<EmployeeTagsSection> createState() =>
      _EmployeeTagsSectionState();
}

class _EmployeeTagsSectionState extends ConsumerState<EmployeeTagsSection> {
  bool _saving = false;

  bool get _isSelf => widget.employeeId == null;

  Future<void> _save(List<String> values) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(employeeRepositoryProvider);
      if (_isSelf) {
        await repository.updateMe(
          widget.field == EmployeeTagsField.skills
              ? UpdateMyProfileInput(skills: values)
              : UpdateMyProfileInput(certifications: values),
        );
        ref.invalidate(myProfileProvider);
        ref.invalidate(myAuditLogProvider);
      } else {
        await repository.updateEmployeeTags(
          widget.employeeId!,
          skills: widget.field == EmployeeTagsField.skills ? values : null,
          certifications: widget.field == EmployeeTagsField.certifications
              ? values
              : null,
        );
        ref.invalidate(employeeDetailProvider(widget.employeeId!));
        ref.invalidate(employeeAuditLogProvider(widget.employeeId!));
      }
    } on EmployeeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TagInput(
            label: widget.title,
            values: widget.values,
            enabled: !_saving,
            onChanged: _save,
          ),
          if (_saving) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
