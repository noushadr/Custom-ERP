import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/performance_review_providers.dart';
import '../../domain/entities/performance_review_criterion.dart';
import '../../domain/exceptions/performance_review_exception.dart';

const _responseTypeLabels = {'rating': 'Rating (1-5)', 'text': 'Written'};

/// Lets Super Admin/HR-Manager configure the list of review areas every
/// performance review is built from — add, edit, reorder, and
/// archive/delete. Requires `performance.manage`.
class PerformanceReviewCriteriaPage extends ConsumerStatefulWidget {
  const PerformanceReviewCriteriaPage({super.key});

  @override
  ConsumerState<PerformanceReviewCriteriaPage> createState() =>
      _PerformanceReviewCriteriaPageState();
}

class _PerformanceReviewCriteriaPageState
    extends ConsumerState<PerformanceReviewCriteriaPage> {
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(
      performanceReviewCriteriaProvider(_includeArchived),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Review Criteria'),
        actions: [
          IconButton(
            tooltip: 'Add criterion',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _CriterionFormDialog(item: null),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                itemsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text(
                    'Could not load review criteria. Please try again.',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No review criteria yet.');
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          _CriterionCard(
                            item: items[i],
                            allItems: items,
                            index: i,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CriterionCard extends ConsumerWidget {
  const _CriterionCard({
    required this.item,
    required this.allItems,
    required this.index,
  });

  final PerformanceReviewCriterion item;
  final List<PerformanceReviewCriterion> allItems;
  final int index;

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setArchived(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .updateCriterion(item.id, isArchived: value);
      ref.invalidate(performanceReviewCriteriaProvider);
    } on PerformanceReviewException catch (error) {
      if (!context.mounted) return;
      _showError(context, error.message);
    }
  }

  Future<void> _move(BuildContext context, WidgetRef ref, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= allItems.length) return;

    final reordered = [...allItems];
    final moved = reordered.removeAt(index);
    reordered.insert(newIndex, moved);

    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .reorderCriteria([for (final i in reordered) i.id]);
      ref.invalidate(performanceReviewCriteriaProvider);
    } on PerformanceReviewException catch (error) {
      if (!context.mounted) return;
      _showError(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete criterion?'),
        content: Text(
          'This permanently removes "${item.name}" from the review template.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(performanceReviewRepositoryProvider)
          .deleteCriterion(item.id);
      ref.invalidate(performanceReviewCriteriaProvider);
    } on PerformanceReviewException catch (error) {
      if (!context.mounted) return;
      _showError(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              IconButton(
                tooltip: 'Move up',
                icon: const Icon(Icons.arrow_upward, size: 16),
                onPressed: index > 0 ? () => _move(context, ref, -1) : null,
              ),
              IconButton(
                tooltip: 'Move down',
                icon: const Icon(Icons.arrow_downward, size: 16),
                onPressed: index < allItems.length - 1
                    ? () => _move(context, ref, 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: _responseTypeLabels[item.responseType] ??
                      item.responseType,
                  color: AppColors.secondary,
                ),
                if (item.isArchived) ...[
                  const SizedBox(width: 8),
                  const _Chip(label: 'Archived', color: AppColors.textSecondary),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _CriterionFormDialog(item: item),
            ),
          ),
          TextButton(
            onPressed: () => _setArchived(context, ref, !item.isArchived),
            child: Text(item.isArchived ? 'Unarchive' : 'Archive'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _CriterionFormDialog extends ConsumerStatefulWidget {
  const _CriterionFormDialog({required this.item});

  final PerformanceReviewCriterion? item;

  @override
  ConsumerState<_CriterionFormDialog> createState() =>
      _CriterionFormDialogState();
}

class _CriterionFormDialogState extends ConsumerState<_CriterionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String _responseType = 'rating';
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _responseType = widget.item?.responseType ?? 'rating';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(performanceReviewRepositoryProvider);
      final name = _nameController.text.trim();

      if (_isEditing) {
        await repository.updateCriterion(
          widget.item!.id,
          name: name,
          responseType: _responseType,
        );
      } else {
        await repository.createCriterion(
          name: name,
          responseType: _responseType,
        );
      }
      ref.invalidate(performanceReviewCriteriaProvider);
      if (mounted) Navigator.of(context).pop();
    } on PerformanceReviewException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit criterion' : 'Add criterion'),
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
              DropdownButtonFormField<String>(
                initialValue: _responseType,
                decoration: const InputDecoration(labelText: 'Response type'),
                items: const [
                  DropdownMenuItem(value: 'rating', child: Text('Rating (1-5)')),
                  DropdownMenuItem(value: 'text', child: Text('Written')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _responseType = value!),
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
              : Text(_isEditing ? 'Save changes' : 'Add criterion'),
        ),
      ],
    );
  }
}
