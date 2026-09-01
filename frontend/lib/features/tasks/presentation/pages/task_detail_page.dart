import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_audit_log_entry.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/exceptions/task_exception.dart';
import '../widgets/task_badges.dart';
import 'task_editor_page.dart';

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

/// Shows one task's full detail: fields, a status-change control (open to
/// anyone who can view the task — see TasksService.updateStatus, whose
/// authority is exactly the same set as who may view it), a comment
/// thread, and its change history.
class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          taskAsync.maybeWhen(
            data: (task) => _canEditTask(ref, task)
                ? TextButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskEditorPage(existingTask: task),
                        ),
                      );
                      ref.invalidate(taskProvider(taskId));
                      ref.invalidate(taskHistoryProvider(taskId));
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
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

class _TaskDetailBody extends StatelessWidget {
  const _TaskDetailBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TaskPriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PersonChip(
                name: task.assigneeName,
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
              Text(
                'Due ${formatDisplayDate(task.dueDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(task.description!),
          ],
          const SizedBox(height: 20),
          _StatusControl(task: task),
          const SizedBox(height: 20),
          _CommentsSection(taskId: task.id),
          const SizedBox(height: 16),
          _HistorySection(taskId: task.id),
        ],
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

class _StatusControl extends ConsumerStatefulWidget {
  const _StatusControl({required this.task});

  final Task task;

  @override
  ConsumerState<_StatusControl> createState() => _StatusControlState();
}

class _StatusControlState extends ConsumerState<_StatusControl> {
  bool _saving = false;
  String? _error;

  Future<void> _changeStatus(String status) async {
    if (status == widget.task.status) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(taskRepositoryProvider).updateStatus(widget.task.id, status);
      ref.invalidate(taskProvider(widget.task.id));
      ref.invalidate(taskHistoryProvider(widget.task.id));
      ref.invalidate(myTasksProvider);
      ref.invalidate(tasksAssignedByMeProvider);
      ref.invalidate(teamTasksProvider);
    } on TaskException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: widget.task.status,
                items: [
                  for (final status in TaskStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(formatTaskStatusLabel(status)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) _changeStatus(value);
                      },
              ),
              if (_saving) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
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

    return FormSection(
      title: 'Comments',
      child: Column(
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
      ),
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
