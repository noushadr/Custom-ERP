import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/named_ref.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../leave/presentation/widgets/leave_balances_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/company_notices_section.dart';
import '../widgets/employee_audit_log_panel.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_status_badges.dart';
import 'employee_profile_page.dart';

class UserDashboardPage extends ConsumerWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(myProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: employeeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                error is EmployeeException && error.message == 'Not found.'
                    ? "This login isn't linked to an employee profile, so "
                          "there's nothing personal to show here."
                    : 'Could not load your dashboard. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            data: (employee) => _UserDashboardBody(employee: employee),
          ),
        ),
      ),
    );
  }
}

class _UserDashboardBody extends StatelessWidget {
  const _UserDashboardBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSummaryCard(employee: employee),
          const SizedBox(height: 16),
          const FormSection(
            title: 'Leave Balances',
            child: LeaveBalancesSection(),
          ),
          const SizedBox(height: 16),
          const CompanyNoticesSection(),
          const SizedBox(height: 16),
          const _TeamMembersSection(),
          const SizedBox(height: 16),
          const EmployeeAuditLogPanel(),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmployeeAvatar(
                  fullName: employee.fullName,
                  photoUrl: employee.profilePhotoUrl,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (employee.designation != null)
                        Text(
                          employee.designation!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showChangePasswordDialog(context),
                      icon: const Icon(Icons.password, size: 16),
                      label: const Text('Change password'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const EmployeeProfilePage(employeeId: null),
                        ),
                      ),
                      child: const Text('View full profile'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // A full-width row rather than nested inside the Expanded above,
            // so these chips still have room to wrap at narrow widths instead
            // of being squeezed by the button column next to them.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InfoChip(icon: Icons.badge_outlined, label: employee.employeeCode),
                EmploymentStatusBadge(status: employee.employmentStatus),
                WorkModeBadge(workMode: employee.workMode),
                if (employee.department != null)
                  InfoChip(
                    icon: Icons.apartment_outlined,
                    label: 'Department: ${employee.department!.name}',
                  ),
                if (employee.reportingManager != null)
                  _ReportingManagerChip(manager: employee.reportingManager!),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: employee.profileCompletionPercentage / 100,
                minHeight: 6,
                backgroundColor: AppColors.borderSubtle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profile ${employee.profileCompletionPercentage}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportingManagerChip extends StatelessWidget {
  const _ReportingManagerChip({required this.manager});

  final NamedRef manager;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmployeeAvatar(fullName: manager.name, photoUrl: manager.photoUrl, radius: 12),
        const SizedBox(width: 6),
        Text(
          'Reporting Manager: ${manager.name}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

void _showChangePasswordDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog());
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(_currentController.text, _newController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              validator: (value) =>
                  value != _newController.text ? "Passwords don't match" : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change password'),
        ),
      ],
    );
  }
}

class _TeamMembersSection extends ConsumerWidget {
  const _TeamMembersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myDirectReportsProvider);

    return FormSection(
      title: 'Team Members',
      child: reportsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load your team members.'),
        data: (reports) {
          if (reports.isEmpty) {
            return Text(
              'No team members are assigned to you yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final report in reports) _TeamMemberTile(employee: report),
            ],
          );
        },
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmployeeAvatar(
            fullName: employee.fullName,
            photoUrl: employee.profilePhotoUrl,
            radius: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  employee.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  employee.designation ?? employee.role,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
