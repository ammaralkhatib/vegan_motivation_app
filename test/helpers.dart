import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// AnimatedCritter runs a never-ending breathing scale, which would make
/// `pumpAndSettle` time out. Request reduced motion so critters render their
/// static base frame in tests that pump the feed. Cleared automatically at test
/// teardown.
void disableCritterAnimations(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Drift closes query streams through microtask → zero-duration-timer
/// chains when the tree is disposed. Unmount the providers and pump a few
/// short frames so the whole chain runs inside the test's fake zone instead
/// of tripping the "Timer is still pending" invariant at teardown.
Future<void> unmountAndFlush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}
