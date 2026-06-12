/// Static configuration for RevenueCat (the one allowed networked service —
/// see CLAUDE.md §3). Product/offering/entitlement *ids* are decided here and
/// must match what Ammar sets up in the RevenueCat dashboard.
///
/// The API keys below are placeholders. They are public SDK keys (safe to ship
/// in the binary), but the real values come from the RevenueCat dashboard.
class PurchaseConfig {
  PurchaseConfig._();

  // --- API keys -----------------------------------------------------------
  // TODO(ammar): paste real key from RevenueCat dashboard (Project → API keys).
  // Apple key covers both iOS and macOS App Store apps.
  static const String appleApiKey = 'appl_TODO_REPLACE_WITH_REAL_KEY';
  // TODO(ammar): paste real key from RevenueCat dashboard (Google Play).
  static const String googleApiKey = 'goog_TODO_REPLACE_WITH_REAL_KEY';

  // --- Dev / testing switch ----------------------------------------------
  /// Dev/testing only — forces premium ON for a single run, bypassing
  /// RevenueCat and the cached status. Set it at launch with
  /// `flutter run --dart-define=FORCE_PREMIUM=true`.
  ///
  /// Defaults to `false` in every normal build (the define is absent), so it
  /// can never ship enabled by accident. It only affects in-memory state — it
  /// never writes to the premium prefs cache, so turning the flag off returns
  /// the app to its real (free) status on the next run.
  static const bool forcePremium = bool.fromEnvironment('FORCE_PREMIUM');

  // --- Entitlement --------------------------------------------------------
  /// The single entitlement that unlocks premium. Active = user is premium.
  static const String premiumEntitlementId = 'premium';

  // --- Offerings (one per paywall variant) --------------------------------
  /// Trial paywall shown at the end of onboarding.
  static const String onboardingOfferingId = 'onboarding';

  /// 50%-off paywall shown on locked content / settings.
  static const String defaultOfferingId = 'default';

  /// 80%-off "last chance" paywall, shown once right after onboarding.
  static const String discountOfferingId = 'discount';
}
