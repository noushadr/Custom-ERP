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

  Future<void> _completeItem(EmployeeChecklistItem item, String type) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _CompleteItemDialog(title: item.title),
    );
    if (note == null) return;

    setState(() => _workingItemId = item.id);
    try {
      await ref
          .read(checklistRepositoryProvider)
          .setChecklistItemCompleted(
            widget.employeeId,
            item.id,
            isCompleted: true,
            note: note.isEmpty ? null : note,
          );
      _invalidate(type);
    } on ChecklistException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _workingItemId = null);
    }
  }

  Future<void> _uncompleteItem(EmployeeChecklistItem item, String type) async {
    setState(() => _workingItemId = item.id);
    try {
      await ref
          .read(checklistRepositoryProvider)
          .setChecklistItemCompleted(
            widget.employeeId,
            item.id,
            isCompleted: false,
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
            label: 'Onboarding',
            async: onboardingAsync,
            canManage: widget.canManage,
            workingItemId: _workingItemId,
            onComplete: (item) => _completeItem(item, _onboarding),
            onUncomplete: (item) => _uncompleteItem(item, _onboarding),
          ),
          _ChecklistBlock(
            label: 'Offboarding',
            async: offboardingAsync,
            canManage: widget.canManage,
            workingItemId: _workingItemId,
            onComplete: (item) => _completeItem(item, _offboarding),
            onUncomplete: (item) => _uncompleteItem(item, _offboarding),
          ),
        ],
      ),
    );
  }
}

class _ChecklistBlock extends StatelessWidget {
  const _ChecklistBlock({
    required this.label,
    required this.async,
    required this.canManage,
    required this.workingItemId,
    required this.onComplete,
    required this.onUncomplete,
  });

  final String label;
  final AsyncValue<List<EmployeeChecklistItem>> async;
  final bool canManage;
  final String? workingItemId;
  final ValueChanged<EmployeeChecklistItem> onComplete;
  final ValueChanged<EmployeeChecklistItem> onUncomplete;

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
                  onComplete: () => onComplete(items[i]),
                  onUncomplete: () => onUncomplete(items[i]),
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
    required this.onComplete,
    required this.onUncomplete,
  });

  final EmployeeChecklistItem item;
  final bool canManage;
  final bool isWorking;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 20,
      color: item.isCompleted ? AppColors.success : AppColors.textSecondary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWorking)
          const Padding(
            padding: EdgeInsets.all(1),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (canManage)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item.isCompleted ? onUncomplete : onComplete,
            child: Padding(padding: const EdgeInsets.all(1), child: icon),
          )
        else
          icon,
        const SizedBox(width: 10),
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

class _CompleteItemDialog extends StatefulWidget {
  const _CompleteItemDialog({required this.title});

  final String title;

  @override
  State<_CompleteItemDialog> createState() => _CompleteItemDialogState();
}

class _CompleteItemDialogState extends State<_CompleteItemDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as done?'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_noteController.text),
          child: const Text('Mark as done'),
        ),
      ],
    );
  }
}
