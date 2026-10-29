import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/shared/widgets/responsive_card_row.dart';

Widget _row(double width, int count) => MaterialApp(
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: ResponsiveCardRow(
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(key: ValueKey('card-$i'), height: 40),
        ],
      ),
    ),
  ),
);

void main() {
  void useWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('fills the full width with balanced rows, leaving no gap', (
    tester,
  ) async {
    // 1000px fits four 240px cards across; five cards become 3 + 2, each
    // row stretching to the full width.
    useWideSurface(tester);
    await tester.pumpWidget(_row(1000, 5));

    double right(int i) =>
        tester.getTopRight(find.byKey(ValueKey('card-$i'))).dx;
    double top(int i) => tester.getTopLeft(find.byKey(ValueKey('card-$i'))).dy;

    expect(top(0), top(2));
    expect(top(3), greaterThan(top(2)));
    expect(top(3), top(4));
    expect(right(2), closeTo(1000, 0.5));
    expect(right(4), closeTo(1000, 0.5));
  });

  testWidgets('stacks to one column on a narrow screen', (tester) async {
    useWideSurface(tester);
    await tester.pumpWidget(_row(300, 3));

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('card-1'))).dy,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey('card-0'))).dy),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('card-0'))).width,
      closeTo(300, 0.5),
    );
  });
}
