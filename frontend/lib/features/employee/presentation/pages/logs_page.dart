import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../widgets/company_audit_log_section.dart';
import '../widgets/employee_audit_log_panel.dart';

/// `audit.viewAll` holders (Super Admin, HR/Manager) see the company-wide
/// change history — every employee-field change across the whole company,
/// searchable and paginated; moved out of the Admin Dashboard into its own
/// nav destination 2026-08-30. Everyone else (Team Lead/Employee) sees just
/// their own change history instead — moved here 2026-09-02 from the User
/// Dashboard, where it used to sit as a "Change History" section at the
/// bottom of every viewer's own dashboard.
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final hasCompanyAccess =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('audit.viewAll');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        child: hasCompanyAccess
            ? const CompanyAuditLogSection()
            : const EmployeeAuditLogPanel(),
      ),
    );
  }
}
