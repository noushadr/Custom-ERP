import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/shared/widgets/app_dialog.dart';

Future<void> _pumpApp(WidgetTester tester, {bool barrierDismissible = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppDialog<void>(
              context: context,
              barrierDismissible: barrierDismissible,
              builder: (_) => AlertDialog(
                title: const Text('Test dialog'),
                content: const Text('Body'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pressing Escape closes a dismissible dialog', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Test dialog'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Test dialog'), findsNothing);
  });

  testWidgets('pressing Escape does nothing when barrierDismissible is false', (
    tester,
  ) async {
    await _pumpApp(tester, barrierDismissible: false);

    expect(find.text('Test dialog'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Test dialog'), findsOneWidget);
  });

  testWidgets('the Close button still works normally', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Test dialog'), findsNothing);
  });
}
