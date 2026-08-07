import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_document.dart';
import '../widgets/employee_audit_log_panel.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_education_section.dart';
import '../widgets/employee_salary_history_section.dart';
import '../widgets/employee_status_badges.dart';
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

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    if (isOwnProfile)
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditMyProfilePage(employee: employee),
                          ),
                        ),
                        child: const Text('Edit'),
                      )
                    else if (canManage)
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditEmployeePage(employee: employee),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 20),
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
        const SizedBox(height: 20),
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
              label: 'Team',
              child: Text(employee.team?.name ?? '—'),
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
              child: Text(employee.employmentType),
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
          const SizedBox(height: 24),
          EmployeeSalaryHistorySection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          const SizedBox(height: 24),
          _DocumentStatusSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
        ],
        const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          EmployeeEducationSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
        ],
        const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        _ChipsSection(title: 'Skills', values: employee.skills),
        const SizedBox(height: 24),
        _ChipsSection(
          title: 'Certifications',
          values: employee.certifications,
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
            padding: const EdgeInsets.all(24),
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
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mainContent,
                  if (auditPanel != null) ...[
                    const SizedBox(height: 20),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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

const _requiredDocumentSlots = [
  (type: DocumentType.contract, label: 'Contract'),
  (type: DocumentType.resume, label: 'Resume'),
  (type: DocumentType.cnic, label: 'CNIC / National ID'),
];

/// Shows Uploaded/Pending status for the Contract, Resume, and CNIC document
/// slots. Pass null for [employeeId] to show the current user's own
/// documents; pass an id (requires `employees.manage`) for another
/// employee's.
class _DocumentStatusSection extends ConsumerWidget {
  const _DocumentStatusSection({this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = employeeId == null
        ? ref.watch(myDocumentsProvider)
        : ref.watch(employeeDocumentsProvider(employeeId!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            documentsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Could not load documents.'),
              data: (documents) {
                final uploadedTypes = documents
                    .map((d) => d.documentType)
                    .toSet();
                return Column(
                  children: [
                    for (final slot in _requiredDocumentSlots)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: Text(
                                slot.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: _DocumentStatusBadge(
                                uploaded: uploadedTypes.contains(slot.type),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentStatusBadge extends StatelessWidget {
  const _DocumentStatusBadge({required this.uploaded});

  final bool uploaded;

  @override
  Widget build(BuildContext context) {
    final color = uploaded ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        uploaded ? 'Uploaded' : 'Pending',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (values.isEmpty)
              Text(
                '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in values) Chip(label: Text(value)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
