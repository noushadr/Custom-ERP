import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/employee/presentation/widgets/employee_status_badges.dart';

void main() {
  testWidgets('dense renders smaller padding and icon than the default size', (
    tester,
  ) async {
    Future<void> pump(bool dense) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'Active',
            color: Colors.green,
            icon: Icons.check_circle_outline,
            dense: dense,
          ),
        ),
      ),
    );

    await pump(false);
    final regularContainer = tester.widget<Container>(find.byType(Container));
    final regularIcon = tester.widget<Icon>(find.byType(Icon));
    final regularPadding = regularContainer.padding! as EdgeInsets;

    await pump(true);
    final denseContainer = tester.widget<Container>(find.byType(Container));
    final denseIcon = tester.widget<Icon>(find.byType(Icon));
    final densePadding = denseContainer.padding! as EdgeInsets;

    expect(densePadding.horizontal, lessThan(regularPadding.horizontal));
    expect(densePadding.vertical, lessThan(regularPadding.vertical));
    expect(denseIcon.size, lessThan(regularIcon.size!));
  });

  testWidgets(
    'EmploymentStatusBadge and WorkModeBadge default to the regular size',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EmploymentStatusBadge(status: 'active'),
                WorkModeBadge(workMode: 'remote'),
              ],
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .toList();
      for (final container in containers) {
        final padding = container.padding! as EdgeInsets;
        expect(padding.horizontal, 22); // 11 * 2, the non-dense default
      }
    },
  );
}
