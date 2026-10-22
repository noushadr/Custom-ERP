import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../employee/presentation/widgets/employee_avatar.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/employee_leave_overview.dart';
import '../utils/leave_format_utils.dart';

/// HR/Admin-only table of every active employee's leave for the current year:
/// one "remaining / total" cell per leave type, plus overall Total and
/// Remaining columns. Requires `leave.manage` — gated by the caller.
class AllEmployeesLeaveSection extends ConsumerStatefulWidget {
  const AllEmployeesLeaveSection({super.key});

  @override
  ConsumerState<AllEmployeesLeaveSection> createState() =>
      _AllEmployeesLeaveSectionState();
}

class _AllEmployeesLeaveSectionState
    extends ConsumerState<AllEmployeesLeaveSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(allEmployeeLeaveOverviewProvider);

    return FormSection(
      title: "All Employees' Leave",
      child: overviewAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Row(
          children: [
            const Flexible(child: Text("Could not load employees' leave.")),
            TextButton(
              onPressed: () => ref.invalidate(allEmployeeLeaveOverviewProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return Text(
              'No active employees yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            );
          }

          final query = _query.trim().toLowerCase();
          final visible = query.isEmpty
              ? employees
              : employees
                    .where(
                      (e) =>
                          e.employeeName.toLowerCase().contains(query) ||
                          e.employeeCode.toLowerCase().contains(query) ||
                          (e.departmentName ?? '').toLowerCase().contains(
                            query,
                          ),
                    )
                    .toList();
          // Every row has the same leave types (one balance per non-archived
          // type), so the first row's list defines the columns.
          final leaveTypeNames = [
            for (final b in employees.first.balances) b.leaveTypeName,
          ];
          final year = employees.first.balances.isEmpty
              ? DateTime.now().year
              : employees.first.balances.first.year;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Days remaining / total for $year, per leave type.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name, code or department',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No employees match "$_query".',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                _LeaveTable(rows: visible, leaveTypeNames: leaveTypeNames),
            ],
          );
        },
      ),
    );
  }
}

class _LeaveTable extends StatelessWidget {
  const _LeaveTable({required this.rows, required this.leaveTypeNames});

  final List<EmployeeLeaveOverview> rows;
  final List<String> leaveTypeNames;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    DataColumn numeric(String label, {String? tooltip}) =>
        DataColumn(label: Text(label), tooltip: tooltip, numeric: true);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: 28,
            headingRowHeight: 44,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            columns: [
              const DataColumn(label: Text('Employee')),
              for (final name in leaveTypeNames)
                numeric(name, tooltip: '$name: remaining / total'),
              numeric('Total', tooltip: 'Total days allotted this year'),
              numeric('Remaining', tooltip: 'Total days still available'),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmployeeAvatar(
                            fullName: row.employeeName,
                            photoUrl: row.profilePhotoUrl,
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.employeeName,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                [
                                  row.employeeCode,
                                  if (row.departmentName != null)
                                    row.departmentName!,
                                ].join(' · '),
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    for (final balance in row.balances)
                      DataCell(
                        Text(
                          '${formatLeaveDays(balance.remaining)} / '
                          '${formatLeaveDays(balance.allocated)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: balance.remaining <= 0
                                ? AppColors.error
                                : null,
                          ),
                        ),
                      ),
                    DataCell(
                      Text(
                        formatLeaveDays(row.totalAllocated),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        formatLeaveDays(row.totalRemaining),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: row.totalRemaining <= 0
                              ? AppColors.error
                              : null,
                        ),
                      ),
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
