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

/// The board only ever shows these three columns — no Pending or Cancelled
/// column, per explicit instruction. A task actually in one of those two
/// statuses (set some other way, e.g. self-service progress update) simply
/// doesn't appear on the board; its status is still visible/editable from
/// its own detail page.
const _boardStatuses = [
  TaskStatus.todo,
  TaskStatus.inProgress,
  TaskStatus.completed,
];

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

/// Whether the current viewer heads [departmentId] specifically — the
/// per-task counterpart to [_headsADepartment], used to decide whether an
/// unclaimed card's claim control should offer "assign to any team member"
/// (a Team Lead's authority) or just plain self-claim.
bool _headsThisDepartment(WidgetRef ref, String? departmentId) {
  if (departmentId == null) return false;
  final authState = ref.watch(authControllerProvider);
  final hasOverride =
      authState is AuthAuthenticated &&
      authState.user.hasPermission('tasks.manage');
  if (hasOverride) return true;

  final myProfile = ref.watch(myProfileProvider).valueOrNull;
  final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
  return myProfile != null &&
      departments.any(
        (d) => d.id == departmentId && d.headEmployeeId == myProfile.id,
      );
}

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSeeTeamTab = _headsADepartment(ref);
    final claimableCount =
        ref.watch(claimableTasksProvider).valueOrNull?.length ?? 0;

    final tabs = [
      const Tab(text: 'My Tasks'),
      Tab(
        child: claimableCount > 0
            ? Badge(
                label: Text('$claimableCount'),
                backgroundColor: AppColors.error,
                child: const Text('Available to Claim'),
              )
            : const Text('Available to Claim'),
      ),
      const Tab(text: 'Assigned Tasks'),
      if (canSeeTeamTab) const Tab(text: 'Task Board'),
    ];
    final views = [
      _TaskBoardView(
        asyncTasks: ref.watch(myTasksProvider),
        emptyMessage: 'No tasks assigned to you yet.',
      ),
      _TaskBoardView(
        asyncTasks: ref.watch(claimableTasksProvider),
        emptyMessage: 'No unclaimed tasks for your team right now.',
      ),
      _TaskBoardView(
        asyncTasks: ref.watch(tasksAssignedByMeProvider),
        emptyMessage: "You haven't assigned any tasks yet.",
      ),
      if (canSeeTeamTab)
        _TaskBoardView(
          asyncTasks: ref.watch(teamTasksProvider),
          emptyMessage: 'No team tasks yet.',
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    MaterialPageRoute(builder: (_) => const TaskEditorPage()),
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
    );
  }
}

/// The narrowest a column is ever allowed to get before the board gives up
/// on filling the screen and falls back to fixed-width horizontally
/// scrolling columns instead (a phone or a narrow split-screen window).
const _minColumnWidth = 220.0;
const _columnSpacing = 12.0;

/// A Kanban board: one column per [_boardStatuses] entry, each holding that
/// status's cards sorted by due date — the whole point being that status
/// reads instantly from which column a card sits in, with every field
/// (priority, assignee, due date, comment count) visible on the card
/// itself, no click-through needed to triage a list. Columns stretch to
/// fill the available width on a normal-width screen (see [LayoutBuilder]
/// below); only when there truly isn't room for all three at a readable
/// width does the board fall back to a horizontally-scrolling fixed-width
/// layout, same as before.
class _TaskBoardView extends StatelessWidget {
  const _TaskBoardView({required this.asyncTasks, required this.emptyMessage});

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
        return LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = _boardStatuses.length;
            final fitsWithoutScroll =
                constraints.maxWidth >=
                columnCount * _minColumnWidth +
                    (columnCount - 1) * _columnSpacing;

            final columns = [
              for (final status in _boardStatuses)
                _StatusColumn(
                  status: status,
                  tasks: (tasks.where((t) => t.status == status).toList()
                    ..sort((a, b) => a.dueDate.compareTo(b.dueDate))),
                  fillWidth: fitsWithoutScroll,
                ),
            ];

            if (fitsWithoutScroll) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < columns.length; i++) ...[
                    if (i > 0) const SizedBox(width: _columnSpacing),
                    Expanded(child: columns[i]),
                  ],
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < columns.length; i++) ...[
                    if (i > 0) const SizedBox(width: _columnSpacing),
                    columns[i],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Also a drop target: dropping a dragged card here (see [_TaskCard]'s
/// `Draggable`) moves that task to this column's status.
class _StatusColumn extends ConsumerWidget {
  const _StatusColumn({
    required this.status,
    required this.tasks,
    required this.fillWidth,
  });

  final String status;
  final List<Task> tasks;
  final bool fillWidth;

  Future<void> _handleDrop(
    WidgetRef ref,
    BuildContext context,
    Task dragged,
  ) async {
    if (dragged.status == status) return;
    try {
      await ref
          .read(taskRepositoryProvider)
          .updateProgress(dragged.id, status: status);
      ref.invalidate(myTasksProvider);
      ref.invalidate(tasksAssignedByMeProvider);
      ref.invalidate(teamTasksProvider);
      ref.invalidate(claimableTasksProvider);
    } on TaskException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = taskStatusColor(status);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => _handleDrop(ref, context, details.data),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        return Container(
          width: fillWidth ? null : 232,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDropTarget
                ? color.withValues(alpha: 0.08)
                : AppColors.canvasBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDropTarget ? color : AppColors.borderSubtle,
              width: isDropTarget ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTaskStatusLabel(status),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 4,
                  ),
                  child: Text(
                    isDropTarget ? 'Drop here' : 'No tasks here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 620),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final task in tasks) ...[
                          _TaskCard(task: task),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

/// Which inline control on this card is mid-save — at most one at a time,
/// since they're all triggered by a single tap. Drives which slot shows a
/// spinner in place of its badge/chip/button.
enum _CardField { priority, dueDate, claim }

class _TaskCardState extends ConsumerState<_TaskCard> {
  _CardField? _saving;

  Future<void> _run(_CardField field, Future<void> Function() action) async {
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

  Future<void> _changePriority(String priority) async {
    if (priority == widget.task.priority) return;
    await _run(
      _CardField.priority,
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
      _CardField.dueDate,
      () => ref
          .read(taskRepositoryProvider)
          .updateProgress(widget.task.id, dueDate: _isoDate(picked)),
    );
  }

  Future<void> _claim() async {
    await _run(
      _CardField.claim,
      () => ref.read(taskRepositoryProvider).claimTask(widget.task.id),
    );
  }

  Future<void> _assignTo(String employeeId) async {
    await _run(
      _CardField.claim,
      () => ref
          .read(taskRepositoryProvider)
          .assignTeamMember(widget.task.id, employeeId),
    );
  }

  Widget _buildCard(BuildContext context) {
    final task = widget.task;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: task.id)),
        ),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  task.isUnclaimed
                      ? const CircleAvatar(
                          radius: 9,
                          child: Icon(Icons.groups_outlined, size: 10),
                        )
                      : EmployeeAvatar(
                          fullName: task.assigneeName!,
                          photoUrl: task.assigneePhotoUrl,
                          radius: 9,
                        ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      task.isUnclaimed ? 'Unclaimed' : task.assigneeName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'by ${task.assignedByName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Assigned ${formatMonthDay(_isoDate(task.createdAt))}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              _InlineDueDateChip(
                dueDate: task.dueDate,
                status: task.status,
                updating: _saving == _CardField.dueDate,
                onTap: _changeDueDate,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InlinePriorityMenu(
                    priority: task.priority,
                    updating: _saving == _CardField.priority,
                    onChanged: _changePriority,
                  ),
                  const Spacer(),
                  if (task.isUnclaimed)
                    _saving == _CardField.claim
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _ClaimControl(
                            task: task,
                            onClaim: _claim,
                            onAssign: _assignTo,
                          )
                  else if (task.commentCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${task.commentCount}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    // Trello-style: drop a card on a different column to move it there.
    // Wrapping the fully interactive card in Draggable still lets every
    // tap-target inside it (priority menu, due-date chip, the card itself)
    // work normally — a plain tap never accumulates enough movement to start
    // a drag, so the gesture arena resolves it to the tap recognizer
    // underneath instead.
    return Draggable<Task>(
      data: widget.task,
      feedback: _DragCardPreview(task: widget.task),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

const _claimButtonPadding = EdgeInsets.symmetric(horizontal: 8);
const _claimButtonMinSize = Size(0, 26);

/// The unclaimed card's claim action — plain self-claim for an ordinary team
/// member, or a "Claim for…" picker for whoever heads *this* task's
/// department (a Team Lead's authority): themselves or any active member of
/// their team, matching `TasksService.assignTeamMember`'s own authority.
/// Self-claim still goes through `claimTask` either way (picking yourself
/// from the menu is just a shortcut to it), not `assignTeamMember`.
class _ClaimControl extends ConsumerWidget {
  const _ClaimControl({
    required this.task,
    required this.onClaim,
    required this.onAssign,
  });

  final Task task;
  final VoidCallback onClaim;
  final ValueChanged<String> onAssign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_headsThisDepartment(ref, task.departmentId)) {
      return TextButton(
        style: TextButton.styleFrom(
          padding: _claimButtonPadding,
          minimumSize: _claimButtonMinSize,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onClaim,
        child: const Text('Claim'),
      );
    }

    final myProfile = ref.watch(myProfileProvider).valueOrNull;
    final employeesAsync = ref.watch(employeeListProvider);
    final members =
        (employeesAsync.valueOrNull ?? const [])
            .where(
              (e) =>
                  e.employmentStatus == 'active' &&
                  e.department?.id == task.departmentId,
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return PopupMenuButton<String>(
      tooltip: 'Claim for…',
      padding: EdgeInsets.zero,
      onSelected: (employeeId) {
        if (myProfile != null && employeeId == myProfile.id) {
          onClaim();
        } else {
          onAssign(employeeId);
        }
      },
      itemBuilder: (context) => [
        for (final member in members)
          PopupMenuItem(
            value: member.id,
            child: Text(
              myProfile != null && member.id == myProfile.id
                  ? '${member.fullName} (you)'
                  : member.fullName,
            ),
          ),
      ],
      child: Padding(
        padding: _claimButtonPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Claim for…',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// A lightweight, non-interactive stand-in for the card shown under the
/// pointer while dragging — a fixed width regardless of the source column's
/// actual (possibly fluid) width, so it stays readable during the drag.
class _DragCardPreview extends StatelessWidget {
  const _DragCardPreview({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskPriorityBadge(priority: task.priority, dense: true),
            const SizedBox(height: 6),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same shortcut as the card's due-date chip, for priority instead — tapping the
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

/// A tappable, highlighted due-date chip — opens a date picker right from
/// the list row, the same shortcut [_InlinePriorityMenu] offers for its own
/// field. Due date changes go through `updateProgress`, restricted to the
/// assigner/department-head/tasks.manage tier — a plain assignee tapping
/// this gets the backend's rejection surfaced as a snackbar. Always shows
/// how many days are left (or overdue by), colored by urgency — red once
/// overdue on a
/// still-open task, amber within 3 days, the app's primary tint otherwise —
/// so it's never missed among the card's other metadata.
class _InlineDueDateChip extends StatelessWidget {
  const _InlineDueDateChip({
    required this.dueDate,
    required this.status,
    required this.updating,
    required this.onTap,
  });

  final String dueDate;
  final String status;
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

    final due = DateTime.parse(dueDate);
    final today = DateTime.now();
    final daysLeft = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final isOpen =
        status != TaskStatus.completed && status != TaskStatus.cancelled;
    final overdue = isOpen && daysLeft < 0;
    final color = overdue
        ? AppColors.error
        : isOpen && daysLeft <= 3
        ? AppColors.warning
        : AppColors.primary;
    final daysLabel = overdue
        ? '${-daysLeft}d overdue'
        : daysLeft == 0
        ? 'due today'
        : daysLeft > 0
        ? '${daysLeft}d left'
        // A closed (completed/cancelled) task with a due date in the past —
        // "days left" no longer applies, and it was never actually overdue
        // since it's done.
        : '${-daysLeft}d ago';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 11, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${formatMonthDay(dueDate)} · $daysLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
