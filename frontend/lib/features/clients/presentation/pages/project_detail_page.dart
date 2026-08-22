import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
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
import '../../domain/entities/project_payment_status.dart';
import '../../domain/exceptions/client_exception.dart';
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
          const SizedBox(height: 16),
          FormSection(
            title: 'Pricing',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PriceLine(
                  label: 'Original client price',
                  value: project.originalClientPrice,
                ),
                _PriceLine(
                  label: 'Deduction (${project.deductionRate.toStringAsFixed(0)}%)',
                  value: project.originalClientPrice - project.netPrice,
                  isDeduction: true,
                ),
                _PriceLine(label: 'Net price', value: project.netPrice, bold: true),
                const Divider(height: 20, color: AppColors.borderSubtle),
                _PriceLine(label: 'Cost', value: project.cost, isDeduction: true),
                _PriceLine(label: 'Profit', value: project.profit, bold: true),
                const Divider(height: 20, color: AppColors.borderSubtle),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment status',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    ProjectPaymentStatusBadge(status: project.paymentStatus),
                  ],
                ),
                if (project.paymentStatus == ProjectPaymentStatus.partial) ...[
                  const SizedBox(height: 6),
                  _PriceLine(label: 'Amount paid', value: project.amountPaid),
                  _PriceLine(
                    label: 'Outstanding',
                    value: (project.netPrice - project.amountPaid).clamp(
                      0,
                      project.netPrice,
                    ),
                    isDeduction: true,
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _UpdatePaymentDialog(project: project),
                      );
                      ref.invalidate(projectProvider(project.id));
                    },
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Update Payment'),
                  ),
                ),
              ],
            ),
          ),
          if (project.notes != null && project.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            FormSection(title: 'Notes', child: Text(project.notes!)),
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

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool isDeduction;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            '${isDeduction ? '- ' : ''}PKR ${formatAmount(value)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: isDeduction ? AppColors.error : null,
            ),
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

class _UpdatePaymentDialog extends ConsumerStatefulWidget {
  const _UpdatePaymentDialog({required this.project});

  final Project project;

  @override
  ConsumerState<_UpdatePaymentDialog> createState() =>
      _UpdatePaymentDialogState();
}

class _UpdatePaymentDialogState extends ConsumerState<_UpdatePaymentDialog> {
  late String _status;
  late final TextEditingController _amountPaidController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _status = widget.project.paymentStatus;
    _amountPaidController = TextEditingController(
      text: widget.project.amountPaid.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(clientsRepositoryProvider)
          .updateProject(
            widget.project.id,
            paymentStatus: _status,
            amountPaid: double.tryParse(_amountPaidController.text) ?? 0,
          );
      ref.invalidate(projectProvider(widget.project.id));
      ref.invalidate(projectsListProvider((status: null, clientId: null)));
      if (mounted) Navigator.of(context).pop();
    } on ClientException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Payment'),
      content: SizedBox(
        width: 360,
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
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in ProjectPaymentStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(formatProjectPaymentStatusLabel(status)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            if (_status == ProjectPaymentStatus.partial) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _amountPaidController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount paid (PKR)'),
              ),
            ],
          ],
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
