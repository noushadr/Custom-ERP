import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/features/module_lock/application/module_lock_providers.dart';
import 'package:zera_erp/features/module_lock/data/module_lock_remote_data_source.dart';
import 'package:zera_erp/shared/widgets/module_pin_gate.dart';

class _FakeModuleLockRemoteDataSource implements ModuleLockRemoteDataSource {
  _FakeModuleLockRemoteDataSource(this._correctPin);

  final String _correctPin;

  @override
  Future<bool> verifyPin(String pin) async => pin == _correctPin;
}

Future<void> _pump(WidgetTester tester, {String correctPin = '2803'}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moduleLockRemoteDataSourceProvider.overrideWithValue(
          _FakeModuleLockRemoteDataSource(correctPin),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ModulePinGate(
            moduleKey: 'leads',
            moduleLabel: 'Leads',
            child: Text('Leads content'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the PIN prompt, not the child, when locked', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Leads is PIN-protected'), findsOneWidget);
    expect(find.text('Leads content'), findsNothing);
  });

  testWidgets('shows an error and stays locked on the wrong PIN', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(find.text('Leads content'), findsNothing);
  });

  testWidgets('reveals the child once the correct PIN is entered', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '2803');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Leads content'), findsOneWidget);
    expect(find.text('Leads is PIN-protected'), findsNothing);
  });
}
