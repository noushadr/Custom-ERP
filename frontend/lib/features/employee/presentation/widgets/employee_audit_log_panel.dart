import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/audit_log_entry.dart';

/// Shows who changed what on an employee's record, and when. Pass null for
/// [employeeId] to show the current user's own history; pass an id
/// (requires `employees.manage`) to show another employee's.
class EmployeeAuditLogPanel extends ConsumerWidget {
  const EmployeeAuditLogPanel({super.key, this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogAsync = employeeId == null
        ? ref.watch(myAuditLogProvider)
        : ref.watch(employeeAuditLogProvider(employeeId!));

    return FormSection(
      title: 'Change History',
      child: auditLogAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load change history.'),
        data: (entries) {
          if (entries.isEmpty) {
            return Text(
              'No changes recorded yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _AuditLogRow(entry: entries[i]),
                if (i < entries.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One line per change: field + what changed on the left (ellipsized rather
/// than wrapping), who/when on the right — same shape as the company-wide
/// log's row, so a record never needs more height than a single line.
class _AuditLogRow extends StatelessWidget {
  const _AuditLogRow({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final emphasisStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: entry.fieldLabel, style: emphasisStyle),
                TextSpan(text: ': ${entry.describeChange}'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${entry.actorName} · ${formatDisplayDateTime(entry.createdAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
