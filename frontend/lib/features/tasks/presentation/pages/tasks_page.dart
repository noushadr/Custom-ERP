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
import '../widgets/task_badges.dart';
import 'task_detail_page.dart';
import 'task_editor_page.dart';

/// Whether the current viewer may create tasks and therefore see the
/// Assigned/Team tabs — true for a `tasks.manage` holder, or anyone who
/// heads at least one department (Team Lead's authority, per the Leave
/// Management precedent — see [departmentsProvider]).
bool _canCreateTasks(WidgetRef ref) {
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
    final canCreate = _canCreateTasks(ref);

    final tabs = [
      const Tab(text: 'My Tasks'),
      if (canCreate) const Tab(text: 'Assigned Tasks'),
      if (canCreate) const Tab(text: 'Team Tasks'),
    ];
    final views = [
      _TaskListView(
        asyncTasks: ref.watch(myTasksProvider),
        emptyMessage: 'No tasks assigned to you yet.',
      ),
      if (canCreate)
        _TaskListView(
          asyncTasks: ref.watch(tasksAssignedByMeProvider),
          emptyMessage: "You haven't assigned any tasks yet.",
        ),
      if (canCreate)
        _TaskListView(
          asyncTasks: ref.watch(teamTasksProvider),
          emptyMessage: 'No team tasks yet.',
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                      ),
                    ),
                    if (canCreate) ...[
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: task.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            EmployeeAvatar(
              fullName: task.assigneeName,
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
                    '${task.assigneeName}'
                    '${task.departmentName != null ? ' · ${task.departmentName}' : ''}'
                    ' · Due ${formatDisplayDate(task.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TaskPriorityBadge(priority: task.priority, dense: true),
            const SizedBox(width: 8),
            TaskStatusBadge(status: task.status, dense: true),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
