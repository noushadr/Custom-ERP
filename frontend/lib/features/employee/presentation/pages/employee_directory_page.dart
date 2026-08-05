import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_hierarchy_view.dart';
import 'employee_profile_page.dart';
import 'invite_employee_page.dart';

enum _DirectoryViewMode { list, hierarchy }

class EmployeeDirectoryPage extends ConsumerStatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  ConsumerState<EmployeeDirectoryPage> createState() =>
      _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState
    extends ConsumerState<EmployeeDirectoryPage> {
  _DirectoryViewMode _viewMode = _DirectoryViewMode.list;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canRead = authUser?.hasPermission('employees.read') ?? false;
    final canManage = authUser?.hasPermission('employees.manage') ?? false;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (canRead)
                    SegmentedButton<_DirectoryViewMode>(
                      segments: const [
                        ButtonSegment(
                          value: _DirectoryViewMode.list,
                          icon: Icon(Icons.view_list_outlined, size: 18),
                          label: Text('List'),
                        ),
                        ButtonSegment(
                          value: _DirectoryViewMode.hierarchy,
                          icon: Icon(Icons.account_tree_outlined, size: 18),
                          label: Text('Hierarchy'),
                        ),
                      ],
                      selected: {_viewMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _viewMode = selection.first),
                    ),
                  if (canManage)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InviteEmployeePage(),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Invite Employee'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: canRead
                    ? _DirectoryBody(viewMode: _viewMode)
                    : const _NoDirectoryAccess(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryBody extends ConsumerWidget {
  const _DirectoryBody({required this.viewMode});

  final _DirectoryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Could not load the directory. Please try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (employees) {
        if (employees.isEmpty) {
          return const Center(child: Text('No employees yet.'));
        }

        return switch (viewMode) {
          _DirectoryViewMode.list => _EmployeeList(employees: employees),
          _DirectoryViewMode.hierarchy => EmployeeHierarchyView(
            employees: employees,
          ),
        };
      },
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees});

  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _EmployeeCard(employee: employees[index]),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeProfilePage(employeeId: employee.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmployeeAvatar(
                    fullName: employee.fullName,
                    photoUrl: employee.profilePhotoUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if ((employee.designation ?? '').isNotEmpty)
                          Text(
                            employee.designation!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _EmploymentStatusBadge(status: employee.employmentStatus),
                  _WorkModeBadge(workMode: employee.workMode),
                  _InfoChip(icon: Icons.badge_outlined, label: employee.employeeCode),
                  _InfoChip(icon: Icons.email_outlined, label: employee.email),
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: employee.phoneNumber ?? '—',
                  ),
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label: 'Joined ${formatDisplayDate(employee.joiningDate)}',
                  ),
                  _InfoChip(
                    icon: Icons.cake_outlined,
                    label: employee.dateOfBirth == null
                        ? '—'
                        : formatDisplayDate(employee.dateOfBirth!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
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

class _EmploymentStatusBadge extends StatelessWidget {
  const _EmploymentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', AppColors.success),
      'on_leave' => ('On Leave', AppColors.warning),
      'notice_period' => ('Notice Period', AppColors.warning),
      'resigned' => ('Resigned', AppColors.error),
      'terminated' => ('Terminated', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };

    return _Badge(label: label, color: color);
  }
}

class _WorkModeBadge extends StatelessWidget {
  const _WorkModeBadge({required this.workMode});

  final String workMode;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (workMode) {
      'remote' => ('Remote', Icons.home_outlined),
      'on_site' => ('On-site', Icons.apartment_outlined),
      _ => (workMode, Icons.apartment_outlined),
    };

    return _Badge(label: label, color: AppColors.textSecondary, icon: icon);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _NoDirectoryAccess extends StatelessWidget {
  const _NoDirectoryAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40),
          const SizedBox(height: 12),
          const Text("You don't have access to the full directory."),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EmployeeProfilePage(employeeId: null),
              ),
            ),
            child: const Text('View my profile'),
          ),
        ],
      ),
    );
  }
}
