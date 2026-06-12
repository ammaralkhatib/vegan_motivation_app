import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/paywall/paywall_data.dart';
import '../../features/paywall/paywall_screen.dart';
import 'purchase_providers.dart';

/// The free/premium content split (CLAUDE.md §3). Free users keep two quote
/// categories; premium unlocks all six. This is the single source of truth for
/// category gating — feed, explore, notifications and the widget all read from
/// [unlockedCategoryIdsProvider], never hard-code the split themselves.

/// Categories any user can see, free forever.
const Set<String> freeCategoryIds = {'why_vegan', 'facts'};

/// Categories unlocked only by premium.
const Set<String> premiumCategoryIds = {
  'quick_tips',
  'milestones',
  'staying_strong',
  'youre_awesome',
};

/// All six category ids.
const Set<String> allCategoryIds = {...freeCategoryIds, ...premiumCategoryIds};

/// The categories the current user may see: all six when premium, otherwise
/// just the free two. Reactive — flips live when [isPremiumProvider] changes.
final unlockedCategoryIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(isPremiumProvider) ? allCategoryIds : freeCategoryIds;
});

/// Opens the 50%-off paywall when a free user taps locked content (the
/// `default` RevenueCat offering). Replaced the old placeholder sheet in 005.
Future<void> showPremiumPaywall(BuildContext context) {
  return showPaywall(context, PaywallVariant.defaultOffer);
}
