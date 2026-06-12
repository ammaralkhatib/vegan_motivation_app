import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// A placeholder "this is premium" prompt. Deliberately minimal — no pricing.
///
/// TODO(004): replace with paywall — prompt 004/005 swaps this body for the
/// real 50%-off paywall (the `default` RevenueCat offering).
Future<void> showPremiumSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'This category is part of Veggie Premium',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
