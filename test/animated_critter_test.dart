import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegan_motivation_app/core/critters/animated_critter.dart';

/// Opacity of a named frame (base / blink / happy); the visible frame is 1.
double _frameOpacity(WidgetTester tester, String frame) {
  return tester
      .widget<Opacity>(find.byKey(ValueKey('critter_frame_$frame')))
      .opacity;
}

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Critter.forCategory', () {
    test('maps every category to its companion', () {
      expect(Critter.forCategory('why_vegan'), Critter.cow);
      expect(Critter.forCategory('quick_tips'), Critter.chicken);
      expect(Critter.forCategory('youre_awesome'), Critter.pig);
      expect(Critter.forCategory('facts'), Critter.duck);
      expect(Critter.forCategory('staying_strong'), Critter.goat);
      expect(Critter.forCategory('milestones'), Critter.sheep);
    });

    test('falls back to cow for unknown or null ids', () {
      expect(Critter.forCategory('nope'), Critter.cow);
      expect(Critter.forCategory(null), Critter.cow);
    });
  });

  testWidgets('renders the static base frame when animate is false',
      (tester) async {
    await tester.pumpWidget(
      _host(const AnimatedCritter(critter: Critter.cow, animate: false)),
    );
    await tester.pump();

    expect(_frameOpacity(tester, 'base'), 1);
    expect(_frameOpacity(tester, 'happy'), 0);
    expect(_frameOpacity(tester, 'blink'), 0);

    // No controllers run when static, so the tree settles cleanly.
    await tester.pumpAndSettle();
  });

  testWidgets('tap swaps to the happy frame, then returns to base',
      (tester) async {
    await tester.pumpWidget(
      _host(const AnimatedCritter(critter: Critter.pig)),
    );
    await tester.pump();

    // Starts on the base frame.
    expect(_frameOpacity(tester, 'base'), 1);
    expect(_frameOpacity(tester, 'happy'), 0);

    await tester.tap(find.byType(AnimatedCritter));
    await tester.pump();

    // Happy frame is now on top.
    expect(_frameOpacity(tester, 'happy'), 1);
    expect(_frameOpacity(tester, 'base'), 0);

    // After the ~1.2 s wiggle the critter returns to base.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_frameOpacity(tester, 'happy'), 0);
    expect(_frameOpacity(tester, 'base'), 1);

    // Unmount so the bob controller and blink timer are cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fires the onTap callback', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(AnimatedCritter(
        critter: Critter.duck,
        onTap: () => tapped++,
      )),
    );
    await tester.pump();

    await tester.tap(find.byType(AnimatedCritter));
    await tester.pump();
    expect(tapped, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
