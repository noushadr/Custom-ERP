import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/checklist_providers.dart';
import '../../domain/entities/checklist_template_item.dart';
import '../../domain/exceptions/checklist_exception.dart';

const _workModeLabels = {
  'on_site': 'On-site',
  'remote': 'Remote',
  'hybrid': 'Hybrid',
};

/// Lets Super Admin/HR-Manager configure the onboarding/offboarding
/// checklist items every relevant employee gets — add, edit, reorder, and
/// archive/delete. Requires `employees.manage`.
class ChecklistTemplatesPage extends ConsumerStatefulWidget {
  const ChecklistTemplatesPage({super.key});

  @override
  ConsumerState<ChecklistTemplatesPage> createState() =>
      _ChecklistTemplatesPageState();
}

class _ChecklistTemplatesPageState
    extends ConsumerState<ChecklistTemplatesPage> {
  String _type = 'onboarding';
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final query = (type: _type, includeArchived: _includeArchived);
    final itemsAsync = ref.watch(checklistTemplateItemsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding & Offboarding Checklist'),
        actions: [
          IconButton(
            tooltip: 'Add item',
            icon: const Icon(Icons.add),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _ChecklistTemplateItemFormDialog(
                type: _type,
                item: null,
              ),
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
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'onboarding',
                            label: Text('Onboarding'),
                          ),
                          ButtonSegment(
                            value: 'offboarding',
                            label: Text('Offboarding'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (selection) =>
                            setState(() => _type = selection.first),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                    'Could not load checklist items. Please try again.',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No checklist items yet.');
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          _ChecklistTemplateItemCard(
                            item: items[i],
                            type: _type,
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

class _ChecklistTemplateItemCard extends ConsumerWidget {
  const _ChecklistTemplateItemCard({
    required this.item,
    required this.type,
    required this.allItems,
    required this.index,
  });

  final ChecklistTemplateItem item;
  final String type;
  final List<ChecklistTemplateItem> allItems;
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
          .read(checklistRepositoryProvider)
          .setTemplateItemArchived(item.id, isArchived: value);
      ref.invalidate(checklistTemplateItemsProvider);
    } on ChecklistException catch (error) {
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
          .read(checklistRepositoryProvider)
          .reorderTemplateItems(type, [for (final i in reordered) i.id]);
      ref.invalidate(checklistTemplateItemsProvider);
    } on ChecklistException catch (error) {
      if (!context.mounted) return;
      _showError(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete checklist item?'),
        content: Text(
          'This permanently removes "${item.title}" from the $type checklist template.',
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
      await ref.read(checklistRepositoryProvider).deleteTemplateItem(item.id);
      ref.invalidate(checklistTemplateItemsProvider);
    } on ChecklistException catch (error) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (item.appliesToWorkMode != null) ...[
                      const SizedBox(width: 8),
                      _Chip(
                        label:
                            '${_workModeLabels[item.appliesToWorkMode] ?? item.appliesToWorkMode} only',
                        color: AppColors.secondary,
                      ),
                    ],
                    if (item.isArchived) ...[
                      const SizedBox(width: 8),
                      const _Chip(
                        label: 'Archived',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  _ChecklistTemplateItemFormDialog(type: type, item: item),
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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _ChecklistTemplateItemFormDialog extends ConsumerStatefulWidget {
  const _ChecklistTemplateItemFormDialog({
    required this.type,
    required this.item,
  });

  final String type;
  final ChecklistTemplateItem? item;

  @override
  ConsumerState<_ChecklistTemplateItemFormDialog> createState() =>
      _ChecklistTemplateItemFormDialogState();
}

class _ChecklistTemplateItemFormDialogState
    extends ConsumerState<_ChecklistTemplateItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _appliesToWorkMode;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title);
    _descriptionController = TextEditingController(
      text: widget.item?.description,
    );
    _appliesToWorkMode = widget.item?.appliesToWorkMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(checklistRepositoryProvider);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (_isEditing) {
        await repository.updateTemplateItem(
          widget.item!.id,
          title: title,
          description: description.isEmpty ? null : description,
          appliesToWorkMode: _appliesToWorkMode,
        );
      } else {
        await repository.createTemplateItem(
          type: widget.type,
          title: title,
          description: description.isEmpty ? null : description,
          appliesToWorkMode: _appliesToWorkMode,
        );
      }
      ref.invalidate(checklistTemplateItemsProvider);
      if (mounted) Navigator.of(context).pop();
    } on ChecklistException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit checklist item' : 'Add checklist item'),
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
                controller: _titleController,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_saving,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _appliesToWorkMode,
                decoration: const InputDecoration(
                  labelText: 'Applies to',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Everyone')),
                  DropdownMenuItem(value: 'on_site', child: Text('On-site only')),
                  DropdownMenuItem(value: 'remote', child: Text('Remote only')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybrid only')),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _appliesToWorkMode = value),
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
              : Text(_isEditing ? 'Save changes' : 'Add item'),
        ),
      ],
    );
  }
}
