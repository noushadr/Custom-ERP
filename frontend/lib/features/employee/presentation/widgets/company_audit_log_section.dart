import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/audit_log_entry.dart';

/// Combined change history across every employee — visible only to viewers
/// with `audit.viewAll` (Super Admin, by default seed config).
class CompanyAuditLogSection extends ConsumerWidget {
  const CompanyAuditLogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogAsync = ref.watch(companyAuditLogProvider);

    return FormSection(
      title: 'Company-wide Changes',
      child: auditLogAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load the combined change log.'),
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
                _CompanyAuditLogRow(entry: entries[i]),
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

class _CompanyAuditLogRow extends StatelessWidget {
  const _CompanyAuditLogRow({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.employeeName ?? 'Unknown employee',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              entry.fieldLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(entry.describeChange, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
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
