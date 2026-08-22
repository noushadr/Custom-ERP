import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/role_providers.dart';
import '../../../authentication/domain/entities/role.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/department.dart';
import '../../application/knowledge_base_providers.dart';
import '../../domain/entities/knowledge_base_article.dart';
import '../../domain/entities/knowledge_base_visibility.dart';
import '../../domain/exceptions/knowledge_base_exception.dart';
import '../widgets/knowledge_base_content_view.dart';

/// Create or edit an article: title, visibility targeting, and the rich-
/// text body. Headings/bold/italic/underline/lists/links only — no tables
/// or embeds, since neither is in scope for this feature.
class KnowledgeBaseEditorPage extends ConsumerStatefulWidget {
  const KnowledgeBaseEditorPage({super.key, this.existingArticle});

  /// Null when creating a new article; the current article when editing.
  final KnowledgeBaseArticle? existingArticle;

  @override
  ConsumerState<KnowledgeBaseEditorPage> createState() =>
      _KnowledgeBaseEditorPageState();
}

class _KnowledgeBaseEditorPageState
    extends ConsumerState<KnowledgeBaseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();

  late String _visibilityType;
  late Set<String> _selectedRoleIds;
  late Set<String> _selectedDepartmentIds;

  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingArticle != null;

  bool get _needsRoles =>
      _visibilityType == KnowledgeBaseVisibility.roles ||
      _visibilityType == KnowledgeBaseVisibility.rolesAndDepartments;

  bool get _needsDepartments =>
      _visibilityType == KnowledgeBaseVisibility.departments ||
      _visibilityType == KnowledgeBaseVisibility.rolesAndDepartments;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingArticle;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _quillController = existing != null
        ? QuillController(
            document: documentFromDelta(existing.content),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : QuillController.basic();
    _visibilityType = existing?.visibilityType ?? KnowledgeBaseVisibility.everyone;
    _selectedRoleIds = {...(existing?.targetRoleIds ?? const [])};
    _selectedDepartmentIds = {...(existing?.targetDepartmentIds ?? const [])};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsRoles && _selectedRoleIds.isEmpty) {
      setState(
        () => _errorMessage =
            'Select at least one role for this visibility type.',
      );
      return;
    }
    if (_needsDepartments && _selectedDepartmentIds.isEmpty) {
      setState(
        () => _errorMessage =
            'Select at least one department for this visibility type.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final content = _quillController.document.toDelta().toJson();
    final repository = ref.read(knowledgeBaseRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateArticle(
              widget.existingArticle!.id,
              title: _titleController.text.trim(),
              content: content,
              visibilityType: _visibilityType,
              targetRoleIds: _needsRoles ? _selectedRoleIds.toList() : [],
              targetDepartmentIds: _needsDepartments
                  ? _selectedDepartmentIds.toList()
                  : [],
            )
          : await repository.createArticle(
              title: _titleController.text.trim(),
              content: content,
              visibilityType: _visibilityType,
              targetRoleIds: _needsRoles ? _selectedRoleIds.toList() : [],
              targetDepartmentIds: _needsDepartments
                  ? _selectedDepartmentIds.toList()
                  : [],
            );

      ref.invalidate(knowledgeBaseArticlesProvider);
      ref.invalidate(knowledgeBaseArticleProvider(saved.id));
      if (widget.existingArticle != null) {
        ref.invalidate(knowledgeBaseVersionHistoryProvider(saved.id));
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on KnowledgeBaseException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Article' : 'New Article'),
      ),
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
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _VisibilityPicker(
                      visibilityType: _visibilityType,
                      onVisibilityChanged: (value) =>
                          setState(() => _visibilityType = value),
                      selectedRoleIds: _selectedRoleIds,
                      onRoleToggled: (id, selected) => setState(() {
                        if (selected) {
                          _selectedRoleIds.add(id);
                        } else {
                          _selectedRoleIds.remove(id);
                        }
                      }),
                      selectedDepartmentIds: _selectedDepartmentIds,
                      onDepartmentToggled: (id, selected) => setState(() {
                        if (selected) {
                          _selectedDepartmentIds.add(id);
                        } else {
                          _selectedDepartmentIds.remove(id);
                        }
                      }),
                      showRoles: _needsRoles,
                      showDepartments: _needsDepartments,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          QuillSimpleToolbar(
                            controller: _quillController,
                            config: const QuillSimpleToolbarConfig(
                              showFontFamily: false,
                              showFontSize: false,
                              showSmallButton: false,
                              showStrikeThrough: false,
                              showInlineCode: false,
                              showColorButton: false,
                              showBackgroundColorButton: false,
                              showAlignmentButtons: false,
                              showCodeBlock: false,
                              showQuote: false,
                              showIndent: false,
                              showDirection: false,
                              showSearchButton: false,
                              showSubscript: false,
                              showSuperscript: false,
                              showLineHeightButton: false,
                              showListCheck: false,
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.borderSubtle),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            // minHeight only takes effect when scrollable is
                            // true, which we don't want here (the whole page
                            // already scrolls) — so the minimum height is
                            // enforced with a ConstrainedBox instead.
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 260,
                              ),
                              child: QuillEditor(
                                focusNode: _editorFocusNode,
                                scrollController: _editorScrollController,
                                controller: _quillController,
                                config: const QuillEditorConfig(
                                  placeholder: 'Start writing…',
                                  scrollable: false,
                                  expands: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
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
                        : Text(_isEditing ? 'Save changes' : 'Publish'),
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

class _VisibilityPicker extends ConsumerWidget {
  const _VisibilityPicker({
    required this.visibilityType,
    required this.onVisibilityChanged,
    required this.selectedRoleIds,
    required this.onRoleToggled,
    required this.selectedDepartmentIds,
    required this.onDepartmentToggled,
    required this.showRoles,
    required this.showDepartments,
  });

  final String visibilityType;
  final ValueChanged<String> onVisibilityChanged;
  final Set<String> selectedRoleIds;
  final void Function(String id, bool selected) onRoleToggled;
  final Set<String> selectedDepartmentIds;
  final void Function(String id, bool selected) onDepartmentToggled;
  final bool showRoles;
  final bool showDepartments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who can view this', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: visibilityType,
          onChanged: (value) {
            if (value != null) onVisibilityChanged(value);
          },
          child: const Column(
            children: [
              _VisibilityOption(
                label: 'Everyone',
                value: KnowledgeBaseVisibility.everyone,
              ),
              _VisibilityOption(
                label: 'Specific roles',
                value: KnowledgeBaseVisibility.roles,
              ),
              _VisibilityOption(
                label: 'Specific departments',
                value: KnowledgeBaseVisibility.departments,
              ),
              _VisibilityOption(
                label: 'Specific roles + departments',
                value: KnowledgeBaseVisibility.rolesAndDepartments,
              ),
            ],
          ),
        ),
        if (showRoles) ...[
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final rolesAsync = ref.watch(rolesProvider);
              return rolesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load roles.'),
                data: (roles) => _ChipMultiSelect<Role>(
                  items: roles,
                  idOf: (role) => role.id,
                  labelOf: (role) => role.name,
                  selectedIds: selectedRoleIds,
                  onToggled: onRoleToggled,
                ),
              );
            },
          ),
        ],
        if (showDepartments) ...[
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final departmentsAsync = ref.watch(departmentsProvider);
              return departmentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load departments.'),
                data: (departments) => _ChipMultiSelect<Department>(
                  items: departments,
                  idOf: (dept) => dept.id,
                  labelOf: (dept) => dept.name,
                  selectedIds: selectedDepartmentIds,
                  onToggled: onDepartmentToggled,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      title: Text(label),
      dense: true,
      contentPadding: EdgeInsets.zero,
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
