import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../checklists/presentation/widgets/employee_checklist_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_assets_section.dart';
import '../widgets/employee_audit_log_panel.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_documents_section.dart';
import '../widgets/employee_education_section.dart';
import '../widgets/employee_salary_history_section.dart';
import '../widgets/employee_status_badges.dart';
import '../widgets/employee_tags_section.dart';
import 'edit_employee_page.dart';
import 'edit_my_profile_page.dart';

/// Shows an employee's profile. Pass null for [employeeId] to view the
/// current user's own profile.
class EmployeeProfilePage extends ConsumerWidget {
  const EmployeeProfilePage({super.key, required this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = employeeId == null
        ? ref.watch(myProfileProvider)
        : ref.watch(employeeDetailProvider(employeeId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Profile')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Could not load this profile.')),
        data: (employee) => _ProfileBody(employee: employee),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isOwnProfile =
        authState is AuthAuthenticated &&
        authState.user.email == employee.email;
    final canManage =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('employees.manage');
    final showAuditLog = isOwnProfile || canManage;
    final canImpersonate =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('users.impersonate') &&
        !isOwnProfile &&
        employee.accountStatus != 'disabled';
    final canResetPassword =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('users.manage');

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          Text(
                            employee.designation ?? employee.role,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canResetPassword) ...[
                          OutlinedButton.icon(
                            onPressed: () =>
                                _resetPassword(context, ref, employee),
                            icon: const Icon(Icons.password, size: 16),
                            label: const Text('Reset password'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (canImpersonate) ...[
                          OutlinedButton.icon(
                            onPressed: () =>
                                _loginAsUser(context, ref, employee),
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text('Login as'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (isOwnProfile)
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditMyProfilePage(employee: employee),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          )
                        else if (canManage)
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditEmployeePage(employee: employee),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EmploymentStatusBadge(status: employee.employmentStatus),
                    WorkModeBadge(workMode: employee.workMode),
                    InfoChip(
                      icon: Icons.badge_outlined,
                      label: employee.employeeCode,
                    ),
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
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Work',
          children: [
            _LabeledRow(
              label: 'Employee ID',
              child: Text(employee.employeeCode),
            ),
            _LabeledRow(
              label: 'Department',
              child: Text(employee.department?.name ?? '—'),
            ),
            _LabeledRow(
              label: 'Reporting Manager',
              child: employee.reportingManager == null
                  ? const Text('—')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmployeeAvatar(
                          fullName: employee.reportingManager!.name,
                          photoUrl: employee.reportingManager!.photoUrl,
                          radius: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(employee.reportingManager!.name),
                      ],
                    ),
            ),
            _LabeledRow(
              label: 'Employment type',
              child: Text(formatEmploymentType(employee.employmentType)),
            ),
            _LabeledRow(
              label: 'Employment status',
              child: Text(employee.employmentStatus),
            ),
            _LabeledRow(
              label: 'Joining date',
              child: Text(formatDisplayDate(employee.joiningDate)),
            ),
            if (showAuditLog) ...[
              _LabeledRow(
                label: 'Joining salary',
                child: SalaryHeadlineValue(
                  employeeId: isOwnProfile ? null : employee.id,
                  which: SalaryHeadline.joining,
                ),
              ),
              _LabeledRow(
                label: 'Current salary',
                child: SalaryHeadlineValue(
                  employeeId: isOwnProfile ? null : employee.id,
                  which: SalaryHeadline.current,
                ),
              ),
            ],
            _LabeledRow(
              label: 'Date of leaving',
              child: Text(
                employee.dateOfLeaving == null
                    ? '—'
                    : formatDisplayDate(employee.dateOfLeaving!),
              ),
            ),
          ],
        ),
        if (showAuditLog) ...[
          const SizedBox(height: 16),
          EmployeeSalaryHistorySection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          const SizedBox(height: 16),
          EmployeeAssetsSection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          const SizedBox(height: 16),
          EmployeeDocumentsSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeChecklistSection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Contact',
          children: [
            _LabeledRow(label: 'Company email', child: Text(employee.email)),
            _LabeledRow(
              label: 'Personal email',
              child: Text(employee.personalEmail ?? '—'),
            ),
            _LabeledRow(
              label: 'Phone',
              child: Text(employee.phoneNumber ?? '—'),
            ),
            _LabeledRow(
              label: 'Date of birth',
              child: Text(
                employee.dateOfBirth == null
                    ? '—'
                    : formatDisplayDate(employee.dateOfBirth!),
              ),
            ),
            _LabeledRow(
              label: 'Address',
              child: Text(employee.address ?? '—'),
            ),
          ],
        ),
        if (showAuditLog) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Bank Information',
            children: [
              _LabeledRow(
                label: 'Bank name',
                child: Text(employee.bankName ?? '—'),
              ),
              _LabeledRow(
                label: 'Account title',
                child: Text(employee.accountTitle ?? '—'),
              ),
              _LabeledRow(
                label: 'Account number',
                child: Text(employee.accountNumber ?? '—'),
              ),
              _LabeledRow(
                label: 'Branch code',
                child: Text(employee.branchCode ?? '—'),
              ),
              _LabeledRow(label: 'IBAN', child: Text(employee.iban ?? '—')),
            ],
          ),
          const SizedBox(height: 16),
          EmployeeEducationSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeTagsSection(
            title: 'Skills',
            values: employee.skills,
            field: EmployeeTagsField.skills,
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeTagsSection(
            title: 'Certifications',
            values: employee.certifications,
            field: EmployeeTagsField.certifications,
            employeeId: isOwnProfile ? null : employee.id,
          ),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Emergency contact',
          children: [
            _LabeledRow(
              label: 'Name',
              child: Text(employee.emergencyContactName ?? '—'),
            ),
            _LabeledRow(
              label: 'Phone',
              child: Text(employee.emergencyContactPhone ?? '—'),
            ),
            _LabeledRow(
              label: 'Relation',
              child: Text(employee.emergencyContactRelation ?? '—'),
            ),
          ],
        ),
      ],
    );

    final auditPanel = showAuditLog
        ? EmployeeAuditLogPanel(
            employeeId: isOwnProfile ? null : employee.id,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= Breakpoints.tabletMax && auditPanel != null;

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: mainContent),
                    const SizedBox(width: 24),
                    SizedBox(width: 320, child: auditPanel),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mainContent,
                  if (auditPanel != null) ...[
                    const SizedBox(height: 16),
                    auditPanel,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Switches the active session to [employee], then pops back to the section
/// root so the viewer doesn't stay on a page that may not apply to them.
Future<void> _loginAsUser(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) async {
  try {
    await ref
        .read(authControllerProvider.notifier)
        .impersonate(employee.userId);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  } on AuthException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

/// Confirms, then resets [employee]'s password to a new temporary one and
/// shows it once so the admin/HR can share it directly.
Future<void> _resetPassword(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reset password?'),
      content: Text(
        '${employee.fullName} will need a new temporary password to log '
        'in — this cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Reset password'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final temporaryPassword = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(employee.userId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _TemporaryPasswordDialog(password: temporaryPassword),
    );
  } on AuthException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _TemporaryPasswordDialog extends StatelessWidget {
  const _TemporaryPasswordDialog({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New temporary password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share this with them directly — it will only be shown once.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  password,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A label + value row used inside [_Section] — [child] can be plain text
/// or a richer widget (e.g. an avatar next to a name).
class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}


