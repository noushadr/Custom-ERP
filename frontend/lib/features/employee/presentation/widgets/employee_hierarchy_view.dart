import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/employee_profile_page.dart';
import '../../domain/entities/employee.dart';
import 'employee_avatar.dart';

const _cardWidth = 220.0;
const _headerHeight = 56.0;
const _avatarRadius = 28.0;
const _connectorHeight = 32.0;
const _subtreeSpacing = 20.0;
const _unitWidth = _cardWidth + _subtreeSpacing;
const _connectorColor = Color(0xFFCBD2D9);

/// Shows employees as an org chart: each manager's direct reports are laid
/// out in a row underneath them and connected with tree lines, expandable/
/// collapsible per node. Employees with no [Employee.reportingManager] are
/// shown as top-level roots.
class EmployeeHierarchyView extends StatefulWidget {
  const EmployeeHierarchyView({super.key, required this.employees});

  final List<Employee> employees;

  @override
  State<EmployeeHierarchyView> createState() => _EmployeeHierarchyViewState();
}

class _EmployeeHierarchyViewState extends State<EmployeeHierarchyView> {
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final reportsByManagerId = <String?, List<Employee>>{};
    for (final employee in widget.employees) {
      reportsByManagerId
          .putIfAbsent(employee.reportingManager?.id, () => [])
          .add(employee);
    }
    final roots = reportsByManagerId[null] ?? [];

    if (roots.isEmpty) {
      return const Center(child: Text('No reporting relationships set yet.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final root in roots)
              _buildSubtree(root, reportsByManagerId),
          ],
        ),
      ),
    );
  }

  int _leafCount(
    Employee employee,
    Map<String?, List<Employee>> reportsByManagerId,
  ) {
    final reports = reportsByManagerId[employee.id] ?? [];
    if (reports.isEmpty || _collapsed.contains(employee.id)) return 1;
    return reports.fold(
      0,
      (sum, report) => sum + _leafCount(report, reportsByManagerId),
    );
  }

  Widget _buildSubtree(
    Employee employee,
    Map<String?, List<Employee>> reportsByManagerId,
  ) {
    final reports = reportsByManagerId[employee.id] ?? [];
    final isCollapsed = _collapsed.contains(employee.id);
    final showChildren = reports.isNotEmpty && !isCollapsed;
    // Every node occupies a "slot" of leafCount * unitWidth, with its card
    // centered inside — that reserved half-unit of breathing room on each
    // side is what creates consistent spacing between sibling cards without
    // needing extra padding when slots are placed directly adjacent.
    final totalWidth = _leafCount(employee, reportsByManagerId) * _unitWidth;

    return SizedBox(
      width: totalWidth,
      child: Column(
        children: [
          Center(
            child: _NodeCard(
              employee: employee,
              reportCount: reports.length,
              expanded: showChildren,
              onToggle: reports.isEmpty
                  ? null
                  : () => setState(() {
                      if (isCollapsed) {
                        _collapsed.remove(employee.id);
                      } else {
                        _collapsed.add(employee.id);
                      }
                    }),
            ),
          ),
          if (showChildren) ...[
            CustomPaint(
              size: Size(totalWidth, _connectorHeight),
              painter: _ConnectorPainter(
                childWidths: [
                  for (final report in reports)
                    _leafCount(report, reportsByManagerId) * _unitWidth,
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final report in reports)
                  _buildSubtree(report, reportsByManagerId),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.childWidths});

  final List<double> childWidths;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _connectorColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final centers = <double>[];
    var x = 0.0;
    for (final width in childWidths) {
      centers.add(x + width / 2);
      x += width;
    }

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, midY),
      paint,
    );
    if (centers.length > 1) {
      canvas.drawLine(
        Offset(centers.first, midY),
        Offset(centers.last, midY),
        paint,
      );
    }
    for (final cx in centers) {
      canvas.drawLine(Offset(cx, midY), Offset(cx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.childWidths != childWidths;
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.employee,
    required this.reportCount,
    required this.expanded,
    required this.onToggle,
  });

  final Employee employee;
  final int reportCount;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final workModeIcon = switch (employee.workMode) {
      'remote' => Icons.home_outlined,
      'hybrid' => Icons.sync_alt_outlined,
      _ => Icons.apartment_outlined,
    };

    return Container(
      width: _cardWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeProfilePage(employeeId: employee.id),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    Container(
                      height: _headerHeight,
                      width: double.infinity,
                      color: AppColors.primary,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        workModeIcon,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: _avatarRadius + 8,
                        left: 12,
                        right: 12,
                        bottom: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            employee.fullName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.designation ?? employee.role,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: _headerHeight - _avatarRadius,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: EmployeeAvatar(
                      fullName: employee.fullName,
                      photoUrl: employee.profilePhotoUrl,
                      radius: _avatarRadius,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            InkWell(
              onTap: onToggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: AppColors.textPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$reportCount ${reportCount == 1 ? 'person' : 'people'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
