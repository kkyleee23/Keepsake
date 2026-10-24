import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/shared/widgets/motion.dart';

/// The opacity the tab at [i] is currently painted with.
double opacityOf(WidgetTester tester, int i) {
  final opacities = tester.widgetList<FadeTransition>(
    find.descendant(
      of: find.byType(FadingTabs),
      matching: find.byType(FadeTransition),
    ),
  );
  if (opacities.length > i) return opacities.elementAt(i).opacity.value;
  // AnimatedOpacity paints through an Opacity widget in some versions.
  final plain = tester.widgetList<Opacity>(
    find.descendant(
      of: find.byType(FadingTabs),
      matching: find.byType(Opacity),
    ),
  );
  return plain.elementAt(i).opacity;
}

Widget tabs(int index) => MaterialApp(
  home: FadingTabs(
    index: index,
    children: const [Text('zero'), Text('one'), Text('two'), Text('three')],
  ),
);

void main() {
  // The tab being left used to sit inside a TickerMode that was switched off
  // the moment it stopped being current, so its fade out never ran: it stayed
  // fully opaque and kept covering the tab underneath. Going to a later tab
  // looked fine (it paints on top); going back to an earlier one looked dead.
  testWidgets('the tab you leave fades out, going forward and back', (
    tester,
  ) async {
    await tester.pumpWidget(tabs(0));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 0), 1);

    // Forward: 0 -> 3.
    await tester.pumpWidget(tabs(3));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 3), 1);
    expect(opacityOf(tester, 0), 0, reason: 'tab 0 should have faded out');

    // Back to an earlier tab: 3 -> 2. This is the one that used to fail.
    await tester.pumpWidget(tabs(2));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 2), 1);
    expect(
      opacityOf(tester, 3),
      0,
      reason: 'tab 3 must fade out, or it keeps covering tab 2',
    );
  });

  testWidgets('only the current tab takes taps', (tester) async {
    await tester.pumpWidget(tabs(1));
    await tester.pumpAndSettle();

    final ignoring = tester
        .widgetList<IgnorePointer>(
          find.descendant(
            of: find.byType(FadingTabs),
            matching: find.byType(IgnorePointer),
          ),
        )
        .map((w) => w.ignoring)
        .toList();

    expect(ignoring, [true, false, true, true]);
  });
}
