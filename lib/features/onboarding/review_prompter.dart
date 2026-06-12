import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// Thin seam over the OS review prompt, so tests never invoke the real plugin.
abstract class ReviewPrompter {
  Future<void> requestReview();
}

/// Real implementation. The OS may silently ignore the request (rate limits,
/// not installed from a store, etc.) — that's fine, never surface an error.
class InAppReviewPrompter implements ReviewPrompter {
  const InAppReviewPrompter();

  @override
  Future<void> requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Best-effort only.
    }
  }
}

final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => const InAppReviewPrompter(),
);
