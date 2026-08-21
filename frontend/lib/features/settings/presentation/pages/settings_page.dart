import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../authentication/presentation/pages/role_permissions_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../checklists/presentation/pages/checklist_templates_page.dart';
import '../../../employee/presentation/pages/departments_page.dart';
import '../../../holidays/presentation/pages/holidays_page.dart';
import '../../../leave/presentation/pages/leave_settings_page.dart';
import '../../../performance_reviews/presentation/pages/performance_review_criteria_page.dart';

/// A single home for the admin-configuration screens that used to be
/// scattered across other pages (Departments under Employees, Leave Types
/// under Leaves) plus Roles & Permissions and Public Holidays, which didn't
/// have a home at all before. Each entry is hidden if the viewer lacks the
/// permission it requires.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canManageDepartments =
        authUser?.hasPermission('departments.manage') ?? false;
    final canManageLeave = authUser?.hasPermission('leave.manage') ?? false;
    final canManageRoles = authUser?.hasPermission('roles.manage') ?? false;
    final canManageEmployees =
        authUser?.hasPermission('employees.manage') ?? false;
    final canManagePerformanceReviews =
        authUser?.hasPermission('performance.manage') ?? false;

    final entries = [
      if (canManageDepartments)
        _SettingsEntry(
          icon: Icons.apartment_outlined,
          title: 'Departments',
          subtitle: 'Create, edit, and archive departments',
          builder: (_) => const DepartmentsPage(),
        ),
      if (canManageEmployees)
        _SettingsEntry(
          icon: Icons.checklist_outlined,
          title: 'Onboarding & Offboarding Checklist',
          subtitle: 'Configure the checklist items every employee gets',
          builder: (_) => const ChecklistTemplatesPage(),
        ),
      if (canManageLeave)
        _SettingsEntry(
          icon: Icons.beach_access_outlined,
          title: 'Leave Types & Policies',
          subtitle: 'Configure leave types and adjust balances',
          builder: (_) => const LeaveSettingsPage(),
        ),
      if (canManageLeave)
        _SettingsEntry(
          icon: Icons.calendar_month_outlined,
          title: 'Public Holidays',
          subtitle: 'Dates Leave excludes from working-day counts',
          builder: (_) => const HolidaysPage(),
        ),
      if (canManagePerformanceReviews)
        _SettingsEntry(
          icon: Icons.rate_review_outlined,
          title: 'Performance Review Criteria',
          subtitle: 'Configure the review areas every review is built from',
          builder: (_) => const PerformanceReviewCriteriaPage(),
        ),
      if (canManageRoles)
        _SettingsEntry(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Roles & Permissions',
          subtitle: 'Define custom roles and what they can access',
          builder: (_) => const RolePermissionsPage(),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: entries.isEmpty
              ? const Center(
                  child: Text("You don't have access to any settings."),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => entries[index],
                ),
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: builder)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
