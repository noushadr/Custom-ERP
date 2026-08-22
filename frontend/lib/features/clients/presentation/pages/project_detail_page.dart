import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../../tasks/application/task_providers.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../tasks/presentation/pages/task_editor_page.dart';
import '../../../tasks/presentation/widgets/task_badges.dart';
import '../../application/clients_providers.dart';
import '../../domain/entities/project.dart';
import '../widgets/project_badges.dart';
import 'project_editor_page.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        actions: [
          projectAsync.maybeWhen(
            data: (project) => TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectEditorPage(existingProject: project),
                  ),
                );
                ref.invalidate(projectProvider(projectId));
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: projectAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Could not load this project.'),
            ),
            data: (project) => _ProjectDetailBody(project: project),
          ),
        ),
      ),
    );
  }
}

class _ProjectDetailBody extends ConsumerWidget {
  const _ProjectDetailBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  project.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ProjectTypeBadge(type: project.type),
              const SizedBox(width: 8),
              ProjectStatusBadge(status: project.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            project.clientName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                'Start ${formatDisplayDate(project.startDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (project.endDate != null)
                Text(
                  'End ${formatDisplayDate(project.endDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (project.renewalDate != null)
                Text(
                  'Renews ${formatDisplayDate(project.renewalDate!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (project.notes != null && project.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FormSection(title: 'Notes', child: Text(project.notes!)),
          ],
          if (_hasSeoDetails(project)) ...[
            const SizedBox(height: 16),
            FormSection(
              title: 'SEO Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.packageName != null)
                    _DetailLine(label: 'Package', value: project.packageName!),
                  if (project.backlinksTarget != null)
                    _DetailLine(
                      label: 'Backlinks target',
                      value: project.backlinksTarget!,
                    ),
                  if (project.seoSheetName != null)
                    _DetailLine(
                      label: 'SEO sheet',
                      value: project.seoSheetName!,
                    ),
                  if (project.projectFolderName != null)
                    _DetailLine(
                      label: 'Project folder',
                      value: project.projectFolderName!,
                    ),
                  if (project.workingEmailAccount != null)
                    _DetailLine(
                      label: 'Working email account',
                      value: project.workingEmailAccount!,
                    ),
                  if (project.ahrefsAccount != null)
                    _DetailLine(
                      label: 'Ahrefs account',
                      value: project.ahrefsAccount!,
                    ),
                  if (project.workingEmailAccount != null ||
                      project.ahrefsAccount != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Passwords are kept in the team password manager, not '
                      'stored here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FormSection(
            title: 'Services',
            child: project.services.isEmpty
                ? Text(
                    'No services assigned yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service in project.services)
                        Chip(label: Text(service.name)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Teams (Departments)',
            child: project.targetDepartments.isEmpty
                ? Text(
                    'No departments assigned yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final department in project.targetDepartments)
                        Chip(label: Text(department.name)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Assigned Employees',
            child: project.assignedEmployees.isEmpty
                ? Text(
                    'No employees assigned yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final employee in project.assignedEmployees)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmployeeAvatar(
                              fullName: employee.fullName,
                              photoUrl: employee.photoUrl,
                              radius: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              employee.fullName,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _TasksSection(project: project),
        ],
      ),
    );
  }
}

bool _hasSeoDetails(Project project) =>
    project.packageName != null ||
    project.backlinksTarget != null ||
    project.seoSheetName != null ||
    project.projectFolderName != null ||
    project.workingEmailAccount != null ||
    project.ahrefsAccount != null;

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TasksSection extends ConsumerWidget {
  const _TasksSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksByProjectProvider(project.id));

    return FormSection(
      title: 'Tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Could not load tasks.'),
            data: (tasks) => tasks.isEmpty
                ? Text(
                    'No tasks linked to this project yet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < tasks.length; i++) ...[
                        _TaskRow(task: tasks[i]),
                        if (i < tasks.length - 1)
                          const Divider(
                            height: 16,
                            color: AppColors.borderSubtle,
                          ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskEditorPage(
                      existingTask: null,
                      initialProjectId: project.id,
                    ),
                  ),
                );
                ref.invalidate(tasksByProjectProvider(project.id));
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Task'),
            ),
          ),
        ],
      ),
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
      child: Row(
        children: [
          Expanded(
            child: Text(task.title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          TaskStatusBadge(status: task.status, dense: true),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
