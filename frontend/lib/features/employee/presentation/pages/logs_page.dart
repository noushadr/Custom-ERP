import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../widgets/company_audit_log_section.dart';

/// Company-wide change history — every employee-field change across the
/// whole company, searchable and paginated. Moved out of the Admin
/// Dashboard into its own nav destination 2026-08-30 (it used to render as
/// an embedded `FormSection` at the bottom of `AdminDashboardPage`); gated by
/// `audit.viewAll`, shared with HR/Manager as of the same change (previously
/// Super-Admin-only, matching the tier `Financial Reports`/`Leads` are on).
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('audit.viewAll')) {
      return const AccessDeniedView();
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(child: CompanyAuditLogSection()),
    );
  }
}
