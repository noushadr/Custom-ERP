import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/simple_pager.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/audit_log_entry.dart';

const _pageSize = 10;

/// Shows who changed what on an employee's record, and when. Pass null for
/// [employeeId] to show the current user's own history; pass an id
/// (requires `employees.manage`) to show another employee's. Paginated
/// client-side at 10 rows/page — the backend returns the full list in one
/// call (there's no per-employee volume anywhere close to needing a real
/// paginated endpoint, unlike the company-wide log), so this just slices it.
class EmployeeAuditLogPanel extends ConsumerStatefulWidget {
  const EmployeeAuditLogPanel({super.key, this.employeeId});

  final String? employeeId;

  @override
  ConsumerState<EmployeeAuditLogPanel> createState() =>
      _EmployeeAuditLogPanelState();
}

class _EmployeeAuditLogPanelState extends ConsumerState<EmployeeAuditLogPanel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final auditLogAsync = widget.employeeId == null
        ? ref.watch(myAuditLogProvider)
        : ref.watch(employeeAuditLogProvider(widget.employeeId!));

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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            );
          }

          final totalPages = (entries.length / _pageSize).ceil();
          // Defends against the list shrinking (e.g. after a refetch) while
          // a later page was selected, without mutating state during build.
          final page = _page.clamp(0, totalPages - 1);
          final start = page * _pageSize;
          final pageEntries = entries.sublist(
            start,
            (start + _pageSize).clamp(0, entries.length),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < pageEntries.length; i++) ...[
                _AuditLogRow(entry: pageEntries[i]),
                if (i < pageEntries.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
              if (totalPages > 1) ...[
                const SizedBox(height: 12),
                SimplePager(
                  page: page,
                  totalPages: totalPages,
                  onSelect: (selected) => setState(() => _page = selected),
                ),
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
