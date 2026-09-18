import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/exceptions/task_exception.dart';
import '../widgets/task_badges.dart';
import 'task_detail_page.dart';
import 'task_editor_page.dart';

/// Formats a [DateTime] as an ISO 'YYYY-MM-DD' string — same convention as
/// `task_editor_page.dart`'s and `task_detail_page.dart`'s own local helper.
String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Whether the current viewer heads at least one department — true Team
/// Lead authority, gating the company/department-wide "Task Board" tab.
/// Everyone can create tasks now (to a team, at least) and therefore sees
/// "Assigned Tasks" too — this narrower check is only for the tab that
/// shows *every* task in a headed department.
bool _headsADepartment(WidgetRef ref) {
  final authState = ref.watch(authControllerProvider);
  final hasOverride =
      authState is AuthAuthenticated &&
      authState.user.hasPermission('tasks.manage');
  if (hasOverride) return true;

  final myProfile = ref.watch(myProfileProvider).valueOrNull;
  final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
  return myProfile != null &&
      departments.any((d) => d.headEmployeeId == myProfile.id);
}

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSeeTeamTab = _headsADepartment(ref);

    final tabs = [
      const Tab(text: 'My Tasks'),
      const Tab(text: 'Available to Claim'),
      const Tab(text: 'Assigned Tasks'),
      if (canSeeTeamTab) const Tab(text: 'Task Board'),
    ];
    final views = [
      _TaskListView(
        asyncTasks: ref.watch(myTasksProvider),
        emptyMessage: 'No tasks assigned to you yet.',
      ),
      _TaskListView(
        asyncTasks: ref.watch(claimableTasksProvider),
        emptyMessage: 'No unclaimed tasks for your team right now.',
      ),
      _TaskListView(
        asyncTasks: ref.watch(tasksAssignedByMeProvider),
        emptyMessage: "You haven't assigned any tasks yet.",
      ),
      if (canSeeTeamTab)
        _TaskListView(
          asyncTasks: ref.watch(teamTasksProvider),
          emptyMessage: 'No team tasks yet.',
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        tabs: tabs,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TaskEditorPage(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Task'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: TabBarView(children: views)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.asyncTasks, required this.emptyMessage});

  final AsyncValue<List<Task>> asyncTasks;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return asyncTasks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Could not load tasks. Please try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        final sorted = [...tasks]
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return ListView.separated(
          itemCount: sorted.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.borderSubtle),
          itemBuilder: (context, index) => _TaskRow(task: sorted[index]),
        );
      },
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

/// Which inline control on this row is mid-save — at most one at a time,
/// since they're all triggered by a single tap. Drives which slot shows a
/// spinner in place of its badge/chip/button.
enum _RowField { status, priority, dueDate, claim }

class _TaskRowState extends ConsumerState<_TaskRow> {
  _RowField? _saving;

  Future<void> _run(_RowField field, Future<void> Function() action) async {
    setState(() => _saving = field);
    try {
      await action();
      ref.invalidate(myTasksProvider);
      ref.invalidate(tasksAssignedByMeProvider);
      ref.invalidate(teamTasksProvider);
      ref.invalidate(claimableTasksProvider);
    } on TaskException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (status == widget.task.status) return;
    await _run(
      _RowField.status,
      () => ref
          .read(taskRepositoryProvider)
          .updateProgress(widget.task.id, status: status),
    );
  }

  Future<void> _changePriority(String priority) async {
    if (priority == widget.task.priority) return;
    await _run(
      _RowField.priority,
      () => ref
          .read(taskRepositoryProvider)
          .updateTask(widget.task.id, priority: priority),
    );
  }

  Future<void> _changeDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.task.dueDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    await _run(
      _RowField.dueDate,
      () => ref
          .read(taskRepositoryProvider)
          .updateProgress(widget.task.id, dueDate: _isoDate(picked)),
    );
  }

  Future<void> _claim() async {
    await _run(
      _RowField.claim,
      () => ref.read(taskRepositoryProvider).claimTask(widget.task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: task.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            task.isUnclaimed
                ? const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.groups_outlined, size: 16),
                  )
                : EmployeeAvatar(
                    fullName: task.assigneeName!,
                    photoUrl: task.assigneePhotoUrl,
                    radius: 16,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.isUnclaimed
                        ? 'Unclaimed · ${task.departmentName ?? 'Team'} · Assigned by ${task.assignedByName}'
                        : 'Assigned to ${task.assigneeName}${task.departmentName != null ? ' · ${task.departmentName}' : ''} · Assigned by ${task.assignedByName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _InlinePriorityMenu(
              priority: task.priority,
              updating: _saving == _RowField.priority,
              onChanged: _changePriority,
            ),
            const SizedBox(width: 8),
            _InlineDueDateChip(
              dueDate: task.dueDate,
              updating: _saving == _RowField.dueDate,
              onTap: _changeDueDate,
            ),
            const SizedBox(width: 8),
            if (task.isUnclaimed)
              _saving == _RowField.claim
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(onPressed: _claim, child: const Text('Claim'))
            else
              _InlineStatusMenu(
                status: task.status,
                updating: _saving == _RowField.status,
                onChanged: _changeStatus,
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A `TaskStatusBadge` that doubles as a status-change control — tapping it
/// opens a menu of every status, right from the list row, so changing a
/// task's status no longer requires opening its detail page first (the
/// detail page's own `_StatusControl` still exists for the same action
/// there). The backend enforces exactly the same authority either way
/// (assignee self-service, plus the assigner/department-head/tasks.manage
/// tier), so this is purely a shortcut, not a new capability — an
/// unauthorized attempt still surfaces the backend's rejection as a snackbar
/// rather than silently failing.
class _InlineStatusMenu extends StatelessWidget {
  const _InlineStatusMenu({
    required this.status,
    required this.updating,
    required this.onChanged,
  });

  final String status;
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
      tooltip: 'Change status',
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in TaskStatus.values)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                if (value == status)
                  const Icon(Icons.check, size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(formatTaskStatusLabel(value)),
              ],
            ),
          ),
      ],
      child: TaskStatusBadge(status: status, dense: true),
    );
  }
}

/// Same shortcut as [_InlineStatusMenu], for priority instead — tapping the
/// badge opens a menu of every priority right from the list row. Priority
/// changes go through `updateTask` (the assigner/department-head/
/// tasks.manage tier), not `updateProgress`, so a plain assignee tapping
/// this still gets the backend's rejection surfaced as a snackbar rather
/// than silently succeeding.
class _InlinePriorityMenu extends StatelessWidget {
  const _InlinePriorityMenu({
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
      child: TaskPriorityBadge(priority: priority, dense: true),
    );
  }
}

/// A tappable due-date chip — opens a date picker right from the list row,
/// the same shortcut [_InlineStatusMenu]/[_InlinePriorityMenu] offer for
/// their own fields. Due date changes go through `updateProgress`, which is
/// self-service for the assignee in addition to the usual assigner/
/// department-head/tasks.manage tier.
class _InlineDueDateChip extends StatelessWidget {
  const _InlineDueDateChip({
    required this.dueDate,
    required this.updating,
    required this.onTap,
  });

  final String dueDate;
  final bool updating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (updating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              formatDisplayDate(dueDate),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
