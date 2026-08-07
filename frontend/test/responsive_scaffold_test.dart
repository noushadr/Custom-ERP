import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';
import 'package:zera_erp/features/employee/application/employee_providers.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';
import 'helpers/fake_employee.dart';

Future<void> _setSurfaceWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _authenticatedApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
      employeeRepositoryProvider.overrideWithValue(FakeEmployeeRepository()),
    ],
    child: const ZeraApp(),
  );
}

void main() {
  testWidgets('shows bottom navigation below the mobile breakpoint', (
    tester,
  ) async {
    await _setSurfaceWidth(tester, 480);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows a collapsed rail with labels at tablet width', (
    tester,
  ) async {
    await _setSurfaceWidth(tester, 800);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows an extended sidebar at desktop width', (tester) async {
    await _setSurfaceWidth(tester, 1280);
    await tester.pumpWidget(_authenticatedApp());
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
