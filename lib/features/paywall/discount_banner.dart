import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs/prefs_repository.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../l10n/app_localizations.dart';
import '../streak/open_streak.dart';
import 'paywall_data.dart';
import 'paywall_screen.dart';

/// A dismissible top banner that offers the one-time 80%-off discount. Unlike
/// the auto-hiding [StreakBanner], this one stays put until the user either taps
/// it (which opens the discount paywall) or dismisses it — both consume the
/// one-time offer.
///
/// App Review 5.6 compliance: the discount is **user-initiated** here. The
/// banner never auto-presents a paywall; it only opens one on an explicit tap.
/// It shows once ever — the first time it's eligible it persists
/// `discountOfferShown`, so it never returns on a later launch.
class DiscountBanner extends ConsumerStatefulWidget {
  const DiscountBanner({super.key});

  @override
  ConsumerState<DiscountBanner> createState() => _DiscountBannerState();
}

class _DiscountBannerState extends ConsumerState<DiscountBanner> {
  /// Whether this banner may show for the whole session. Decided **once** in
  /// [initState], before we persist `discountOfferShown` — otherwise setting the
  /// flag would immediately re-gate the banner off and it would never be seen.
  late final bool _eligible;

  /// Set once the user taps the CTA or dismisses — hides the banner for the rest
  /// of the session. The persisted flag keeps it hidden across launches.
  bool _consumed = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(prefsProvider);
    // Collision rule (Req 4): the StreakBanner owns top-center on the first
    // launch of a new calendar day. Rather than stack two pills in the same
    // spot, the discount banner simply yields whenever the streak banner is
    // showing; it reappears on a later launch when the streak banner isn't.
    final streakShowing = ref.read(appOpenStreakProvider).showBanner;
    _eligible = !ref.read(isPremiumProvider) &&
        !prefs.discountOfferShown &&
        prefs.onboardingDone &&
        !streakShowing;
    if (_eligible) {
      // Persist the moment it's actually shown — one-time semantics, matching
      // the old funnel behavior. Tapping the CTA or dismissing both leave it
      // true, so the offer never repeats.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prefs.setDiscountOfferShown(true);
      });
    }
  }

  void _openPaywall() {
    setState(() => _consumed = true);
    showPaywall(context, PaywallVariant.discount);
  }

  void _dismiss() => setState(() => _consumed = true);

  @override
  Widget build(BuildContext context) {
    // Hide if never eligible, already consumed, or premium arrived mid-session.
    if (!_eligible || _consumed || ref.watch(isPremiumProvider)) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Material(
          color: scheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openPaywall,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 6, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: scheme.onInverseSurface,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.discountBannerTitle,
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l.discountBannerMessage,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onInverseSurface
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _openPaywall,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.inversePrimary,
                    ),
                    child: Text(l.discountBannerCta),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close),
                    color: scheme.onInverseSurface,
                    tooltip: l.discountBannerDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
