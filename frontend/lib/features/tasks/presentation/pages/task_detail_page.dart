import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/domain/entities/employee.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_audit_log_entry.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/exceptions/task_exception.dart';
import '../widgets/task_badges.dart';

/// Formats a [DateTime] as an ISO 'YYYY-MM-DD' string — same convention as
/// `task_editor_page.dart`'s own local helper.
String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Whether the viewer may edit this task's core fields (title/description/
/// assignee/priority/due date) — a `tasks.manage` holder (Super Admin/
/// HR-Manager), the task's assigner, or the head of the task's (assignee's)
/// department (a Team Lead's authority) — i.e. admin, TLs, and HR can all
/// edit. Narrower than who may view the task or change its status only in
/// that the assignee alone cannot edit these fields (they get their own
/// status-only self-service in `updateStatus`) — see TasksService.canEdit
/// on the backend, which this mirrors.
bool _canEditTask(WidgetRef ref, Task task) {
  final authState = ref.watch(authControllerProvider);
  final authUser = authState is AuthAuthenticated ? authState.user : null;
  if (authUser?.hasPermission('tasks.manage') ?? false) return true;
  if (authUser != null && authUser.id == task.assignedByUserId) return true;

  final myProfile = ref.watch(myProfileProvider).valueOrNull;
  final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
  if (myProfile == null || task.departmentId == null) return false;
  return departments.any(
    (d) => d.id == task.departmentId && d.headEmployeeId == myProfile.id,
  );
}

/// Shows one task's full detail: fields directly editable in place for
/// whoever can edit the task (title/description/priority/due date — see
/// `_canEditTask`, which mirrors `TasksService.canEdit`) with no separate
/// edit page to navigate to; status stays read-only here since it's already
/// tap-to-change from the tasks list row (`_InlineStatusMenu`). A single
/// comment thread covers both discussion and progress updates (open to
/// anyone who can view the task — see TasksService.canView, which
/// addComment reuses), plus the change history.
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskProvider(taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: taskAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this task.'),
            ),
            data: (task) => _TaskDetailBody(task: task),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailBody extends ConsumerStatefulWidget {
  const _TaskDetailBody({required this.task});

  final Task task;

  @override
  ConsumerState<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends ConsumerState<_TaskDetailBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  String? _fieldSaving;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _save(
    String field, {
    String? title,
    String? description,
    String? priority,
    String? dueDate,
  }) async {
    setState(() {
      _fieldSaving = field;
      _error = null;
    });
    try {
      await ref
          .read(taskRepositoryProvider)
          .updateTask(
            widget.task.id,
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate,
          );
      ref.invalidate(taskProvider(widget.task.id));
      ref.invalidate(taskHistoryProvider(widget.task.id));
      ref.invalidate(myTasksProvider);
      ref.invalidate(tasksAssignedByMeProvider);
      ref.invalidate(teamTasksProvider);
    } on TaskException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _fieldSaving = null);
    }
  }

  void _saveTitleIfChanged() {
    final value = _titleController.text.trim();
    if (value.isEmpty || value == widget.task.title) return;
    _save('title', title: value);
  }

  void _saveDescriptionIfChanged() {
    final value = _descriptionController.text.trim();
    if (value == (widget.task.description ?? '')) return;
    _save('description', description: value);
  }

  Future<void> _changePriority(String priority) async {
    if (priority == widget.task.priority) return;
    await _save('priority', priority: priority);
  }

  Future<void> _changeDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.task.dueDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    await _save('dueDate', dueDate: _isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final canEdit = _canEditTask(ref, task);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: canEdit
                    ? TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          filled: false,
                        ),
                        onTapOutside: (_) {
                          _titleFocus.unfocus();
                          _saveTitleIfChanged();
                        },
                        onSubmitted: (_) => _saveTitleIfChanged(),
                      )
                    : Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
              ),
              if (_fieldSaving == 'title') ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              if (!task.isUnclaimed) ...[
                const SizedBox(width: 8),
                TaskStatusBadge(status: task.status),
              ],
              const SizedBox(width: 8),
              canEdit
                  ? _PriorityMenu(
                      priority: task.priority,
                      updating: _fieldSaving == 'priority',
                      onChanged: _changePriority,
                    )
                  : TaskPriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!task.isUnclaimed)
                _PersonChip(
                  name: task.assigneeName!,
                  photoUrl: task.assigneePhotoUrl,
                  label: 'Assigned to ${task.assigneeName}',
                ),
              _PersonChip(
                name: task.assignedByName,
                photoUrl: task.assignedByPhotoUrl,
                label: 'Assigned by ${task.assignedByName}',
              ),
              if (task.departmentName != null)
                Text(
                  'Department: ${task.departmentName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              _DueDateChip(
                dueDate: task.dueDate,
                status: task.status,
                updating: _fieldSaving == 'dueDate',
                onTap: canEdit ? _changeDueDate : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          canEdit
              ? TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  maxLines: null,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Add a description',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onTapOutside: (_) {
                    _descriptionFocus.unfocus();
                    _saveDescriptionIfChanged();
                  },
                  onSubmitted: (_) => _saveDescriptionIfChanged(),
                )
              : (task.description != null && task.description!.isNotEmpty
                    ? Text(task.description!)
                    : const SizedBox.shrink()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          if (task.isUnclaimed) ...[
            _AssignmentSection(task: task),
            const SizedBox(height: 20),
          ],
          FormSection(
            title: 'Comments',
            child: _CommentsSection(taskId: task.id),
          ),
          const SizedBox(height: 16),
          _HistorySection(taskId: task.id),
        ],
      ),
    );
  }
}

/// Same tap-a-badge-to-change-it shortcut the tasks list row's own priority
/// menu offers — used here so priority editing on the detail page needs no
/// separate form either.
class _PriorityMenu extends StatelessWidget {
  const _PriorityMenu({
    required this.priority,
    required this.updating,
    required this.onChanged,
  });

  final String priority;
  final bool updating;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (updating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Change priority',
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in TaskPriority.values)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                if (value == priority)
                  const Icon(Icons.check, size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(value[0].toUpperCase() + value.substring(1)),
              ],
            ),
          ),
      ],
      child: TaskPriorityBadge(priority: priority),
    );
  }
}

/// A highlighted (never plain-text) due-date pill — colored by urgency so it
/// stands out from the surrounding metadata at a glance: red once overdue
/// (and still open), amber within 3 days, the app's own primary tint
/// otherwise. Tappable to change it when [onTap] is given.
class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.dueDate,
    required this.status,
    required this.updating,
    required this.onTap,
  });

  final String dueDate;
  final String status;
  final bool updating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (updating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final due = DateTime.parse(dueDate);
    final today = DateTime.now();
    final daysLeft = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final isOpen =
        status != TaskStatus.completed && status != TaskStatus.cancelled;
    final Color color = isOpen && daysLeft < 0
        ? AppColors.error
        : isOpen && daysLeft <= 3
        ? AppColors.warning
        : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              isOpen && daysLeft < 0
                  ? 'Overdue · ${formatDisplayDate(dueDate)}'
                  : 'Due ${formatDisplayDate(dueDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small avatar + label, used for the "Assigned to"/"Assigned by" lines so
/// each person is visually identifiable, not just named.
class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    required this.photoUrl,
    required this.label,
  });

  final String name;
  final String? photoUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmployeeAvatar(fullName: name, photoUrl: photoUrl, radius: 10),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Shown while a task has no assignee yet —
/// any member of its team can accept it outright, and the team's head (or
/// a `tasks.manage` holder) can pick a specific member for it.
class _AssignmentSection extends ConsumerStatefulWidget {
  const _AssignmentSection({required this.task});

  final Task task;

  @override
  ConsumerState<_AssignmentSection> createState() => _AssignmentSectionState();
}

class _AssignmentSectionState extends ConsumerState<_AssignmentSection> {
  String? _selectedEmployeeId;
  bool _acting = false;
  String? _error;

  void _refreshAfterChange() {
    ref.invalidate(taskProvider(widget.task.id));
    ref.invalidate(taskHistoryProvider(widget.task.id));
    ref.invalidate(myTasksProvider);
    ref.invalidate(claimableTasksProvider);
    ref.invalidate(teamTasksProvider);
  }

  Future<void> _claim() async {
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await ref.read(taskRepositoryProvider).claimTask(widget.task.id);
      _refreshAfterChange();
    } on TaskException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _assignMember() async {
    final employeeId = _selectedEmployeeId;
    if (employeeId == null) return;
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await ref
          .read(taskRepositoryProvider)
          .assignTeamMember(widget.task.id, employeeId);
      _refreshAfterChange();
    } on TaskException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hasOverride =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('tasks.manage');
    final myProfile = ref.watch(myProfileProvider).valueOrNull;
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final isTeamMember =
        myProfile != null &&
        myProfile.department?.id == widget.task.departmentId;
    final headsThisTeam =
        hasOverride ||
        (myProfile != null &&
            departments.any(
              (d) =>
                  d.id == widget.task.departmentId &&
                  d.headEmployeeId == myProfile.id,
            ));

    return FormSection(
      title: 'Unclaimed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This task is assigned to ${widget.task.departmentName ?? 'a team'} '
            '— nobody has picked it up yet.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (isTeamMember) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _acting ? null : _claim,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept this task'),
            ),
          ],
          if (headsThisTeam) ...[
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final employeesAsync = ref.watch(employeeListProvider);
                return employeesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not load employees.'),
                  data: (employees) {
                    final members = employees
                        .where(
                          (e) =>
                              e.employmentStatus == 'active' &&
                              e.department?.id == widget.task.departmentId,
                        )
                        .toList();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedEmployeeId,
                            decoration: const InputDecoration(
                              labelText: 'Assign a team member',
                            ),
                            items: [
                              for (final Employee employee in members)
                                DropdownMenuItem(
                                  value: employee.id,
                                  child: Text(employee.fullName),
                                ),
                            ],
                            onChanged: _acting
                                ? null
                                : (value) => setState(
                                    () => _selectedEmployeeId = value,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _acting || _selectedEmployeeId == null
                              ? null
                              : _assignMember,
                          child: const Text('Assign'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.taskId});

  final String taskId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _posting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      await ref.read(taskRepositoryProvider).addComment(widget.taskId, body);
      _controller.clear();
      ref.invalidate(taskCommentsProvider(widget.taskId));
    } on TaskException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Could not load comments.'),
          data: (comments) => comments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No comments yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < comments.length; i++) ...[
                      _CommentTile(comment: comments[i]),
                      if (i < comments.length - 1)
                        const Divider(
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('comment-input'),
          controller: _controller,
          enabled: !_posting,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a comment',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final TaskComment comment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${comment.authorName} · ${formatDisplayDateOnly(comment.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(comment.body),
      ],
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(taskHistoryProvider(taskId));

    return FormSection(
      title: 'History',
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Could not load history.'),
        data: (entries) => entries.isEmpty
            ? Text(
                'No history yet.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    _HistoryLine(entry: entries[i]),
                    if (i < entries.length - 1)
                      const Divider(height: 16, color: AppColors.borderSubtle),
                  ],
                ],
              ),
      ),
    );
  }
}

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({required this.entry});

  final TaskAuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final oldValue = entry.oldValue;
    final newValue = entry.newValue;
    final description = entry.fieldLabel == 'Created'
        ? '${entry.actorName} created this task'
              '${newValue != null ? ' — $newValue' : ''}'
        : '${entry.actorName} changed ${entry.fieldLabel}'
              '${oldValue != null ? ' from ${_formatValue(entry.fieldLabel, oldValue)}' : ''}'
              '${newValue != null ? ' to ${_formatValue(entry.fieldLabel, newValue)}' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          formatDisplayDateOnly(entry.createdAt),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatValue(String fieldLabel, String value) {
    if (fieldLabel == 'Status') return formatTaskStatusLabel(value);
    return value;
  }
}
