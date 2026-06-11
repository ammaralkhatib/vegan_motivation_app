import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
