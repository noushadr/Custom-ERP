import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/authentication/application/auth_providers.dart';
import 'package:zera_erp/features/authentication/application/auth_state.dart';

import 'package:zera_erp/main.dart';
import 'helpers/fake_auth.dart';

Widget _authenticatedApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => PresetAuthController(const AuthAuthenticated(testAuthUser)),
      ),
    ],
    child: const ZeraApp(),
  );
}

void main() {
  testWidgets('renders the dashboard placeholder by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());

    expect(find.text('Dashboard — coming soon'), findsOneWidget);
  });

  testWidgets('switching destinations updates the body', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authenticatedApp());

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings — coming soon'), findsOneWidget);
  });
}
