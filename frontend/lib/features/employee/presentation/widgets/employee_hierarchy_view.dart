import 'package:flutter/material.dart';
import '../pages/employee_profile_page.dart';
import '../../domain/entities/employee.dart';
import 'employee_avatar.dart';

/// Shows employees as an org chart: each manager's direct reports nest
/// underneath them, expandable/collapsible. Employees with no
/// [Employee.reportingManager] are shown as top-level roots.
class EmployeeHierarchyView extends StatelessWidget {
  const EmployeeHierarchyView({super.key, required this.employees});

  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    final reportsByManagerId = <String?, List<Employee>>{};
    for (final employee in employees) {
      reportsByManagerId
          .putIfAbsent(employee.reportingManager?.id, () => [])
          .add(employee);
    }
    final roots = reportsByManagerId[null] ?? [];

    if (roots.isEmpty) {
      return const Center(child: Text('No reporting relationships set yet.'));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final root in roots)
          _HierarchyNode(
            employee: root,
            reportsByManagerId: reportsByManagerId,
            depth: 0,
          ),
      ],
    );
  }
}

class _HierarchyNode extends StatelessWidget {
  const _HierarchyNode({
    required this.employee,
    required this.reportsByManagerId,
    required this.depth,
  });

  final Employee employee;
  final Map<String?, List<Employee>> reportsByManagerId;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final reports = reportsByManagerId[employee.id] ?? [];
    final indent = 16.0 + depth * 28;
    final avatar = EmployeeAvatar(
      fullName: employee.fullName,
      photoUrl: employee.profilePhotoUrl,
      radius: 18,
    );

    final subtitleParts = [
      employee.designation,
      employee.department?.name,
      if (reports.isNotEmpty)
        '${reports.length} report${reports.length == 1 ? '' : 's'}',
    ].where((v) => v != null && v.isNotEmpty).join(' • ');
    final subtitle = subtitleParts.isEmpty ? null : Text(subtitleParts);

    void openProfile() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeProfilePage(employeeId: employee.id),
      ),
    );

    if (reports.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: EdgeInsets.only(left: indent, right: 16),
          leading: avatar,
          title: Text(employee.fullName),
          subtitle: subtitle,
          onTap: openProfile,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.only(left: indent, right: 16),
          leading: avatar,
          title: Text(employee.fullName),
          subtitle: subtitle,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.only(left: indent, right: 16),
              title: const Text('View profile'),
              leading: const Icon(Icons.arrow_forward, size: 18),
              onTap: openProfile,
            ),
            for (final report in reports)
              _HierarchyNode(
                employee: report,
                reportsByManagerId: reportsByManagerId,
                depth: depth + 1,
              ),
          ],
        ),
      ),
    );
  }
}
