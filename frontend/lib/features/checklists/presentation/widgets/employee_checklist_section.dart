import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/checklist_providers.dart';
import '../../domain/entities/employee_checklist_item.dart';
import '../../domain/exceptions/checklist_exception.dart';

const _onboarding = 'onboarding';
const _offboarding = 'offboarding';

/// Onboarding/offboarding checklist progress for an employee — visible to
/// the employee themselves (read-only) and to HR/Admin (who can check items
/// off). Each block (onboarding/offboarding) only renders once that
/// checklist actually has items — a currently-active employee simply has no
/// offboarding block yet. [employeeId] is always the real employee id; set
/// [isSelf] to read via the self-service endpoint instead of the
/// `employees.manage`-gated one.
class EmployeeChecklistSection extends ConsumerStatefulWidget {
  const EmployeeChecklistSection({
    super.key,
    required this.employeeId,
    required this.isSelf,
    required this.canManage,
  });

  final String employeeId;
  final bool isSelf;
  final bool canManage;

  @override
  ConsumerState<EmployeeChecklistSection> createState() =>
      _EmployeeChecklistSectionState();
}

class _EmployeeChecklistSectionState
    extends ConsumerState<EmployeeChecklistSection> {
  String? _workingItemId;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _invalidate(String type) {
    ref.invalidate(
      employeeChecklistProvider((employeeId: widget.employeeId, type: type)),
    );
    if (widget.isSelf) ref.invalidate(myChecklistProvider(type));
  }

  Future<void> _toggleItem(
    EmployeeChecklistItem item,
    String type,
    bool isCompleted,
  ) async {
    setState(() => _workingItemId = item.id);
    try {
      await ref
          .read(checklistRepositoryProvider)
          .setChecklistItemCompleted(
            widget.employeeId,
            item.id,
            isCompleted: isCompleted,
          );
      _invalidate(type);
    } on ChecklistException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _workingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = widget.isSelf
        ? ref.watch(myChecklistProvider(_onboarding))
        : ref.watch(
            employeeChecklistProvider((
              employeeId: widget.employeeId,
              type: _onboarding,
            )),
          );
    final offboardingAsync = widget.isSelf
        ? ref.watch(myChecklistProvider(_offboarding))
        : ref.watch(
            employeeChecklistProvider((
              employeeId: widget.employeeId,
              type: _offboarding,
            )),
          );

    return FormSection(
      title: 'Checklists',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChecklistBlock(
            label: 'Onboarding Checklist',
            async: onboardingAsync,
            canManage: widget.canManage,
            workingItemId: _workingItemId,
            onToggle: (item, isCompleted) =>
                _toggleItem(item, _onboarding, isCompleted),
          ),
          _ChecklistBlock(
            label: 'Offboarding Checklist',
            async: offboardingAsync,
            canManage: widget.canManage,
            workingItemId: _workingItemId,
            onToggle: (item, isCompleted) =>
                _toggleItem(item, _offboarding, isCompleted),
          ),
        ],
      ),
    );
  }
}

typedef _ToggleCallback = void Function(EmployeeChecklistItem item, bool isCompleted);

class _ChecklistBlock extends StatelessWidget {
  const _ChecklistBlock({
    required this.label,
    required this.async,
    required this.canManage,
    required this.workingItemId,
    required this.onToggle,
  });

  final String label;
  final AsyncValue<List<EmployeeChecklistItem>> async;
  final bool canManage;
  final String? workingItemId;
  final _ToggleCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Could not load the $label checklist.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final completedCount = items.where((i) => i.isCompleted).length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label ($completedCount/${items.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < items.length; i++) ...[
                _ChecklistItemRow(
                  item: items[i],
                  canManage: canManage,
                  isWorking: workingItemId == items[i].id,
                  onToggle: (isCompleted) => onToggle(items[i], isCompleted),
                ),
                if (i < items.length - 1)
                  const Divider(height: 16, color: AppColors.borderSubtle),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  const _ChecklistItemRow({
    required this.item,
    required this.canManage,
    required this.isWorking,
    required this.onToggle,
  });

  final EmployeeChecklistItem item;
  final bool canManage;
  final bool isWorking;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWorking)
          const Padding(
            padding: EdgeInsets.all(9),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Checkbox(
            value: item.isCompleted,
            activeColor: AppColors.success,
            onChanged: canManage
                ? (value) => onToggle(value ?? false)
                : null,
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.isCompleted ? AppColors.textSecondary : null,
                ),
              ),
              if (item.isCompleted && item.completedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.completedByName != null)
                      'Done by ${item.completedByName}',
                    formatDisplayDateTime(item.completedAt!),
                    if (item.note != null && item.note!.isNotEmpty) item.note!,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
