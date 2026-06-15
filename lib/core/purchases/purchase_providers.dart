import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchase_config.dart';
import 'purchase_service.dart';

/// The app's purchase layer. Created in main() and provided via override,
/// mirroring [prefsProvider]/[databaseProvider]. Tests override it with a
/// fake.
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) =>
      throw UnimplementedError('purchaseServiceProvider must be overridden'),
);

/// Whether the user currently has premium. Seeded from the service's cached
/// value (so it's correct on the first frame, offline) and updated live as the
/// store reports changes. Read this everywhere feature gating is needed.
class PremiumStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Dev/testing escape hatch (see [PurchaseConfig.forcePremium]): when the
    // app is run with `--dart-define=FORCE_PREMIUM=true`, premium is forced on
    // for that run, regardless of RevenueCat or the cached value. This is the
    // single point the flag is applied — everything downstream (gating,
    // paywalls, settings rows, the onboarding funnel) just follows. It never
    // touches the prefs cache, so the real (free) state returns next run.
    if (PurchaseConfig.forcePremium) return true;

    final service = ref.watch(purchaseServiceProvider);
    final sub = service.isPremiumStream.listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return service.isPremium;
  }
}

final isPremiumProvider = NotifierProvider<PremiumStatusNotifier, bool>(
  PremiumStatusNotifier.new,
);

/// Active-subscription details for the Settings card. Reloads when premium
/// flips. Returns null (without touching the service) when not premium, so a
/// free user never triggers an SDK call.
final subscriptionDetailsProvider = FutureProvider<SubscriptionDetails?>((
  ref,
) async {
  final isPremium = ref.watch(isPremiumProvider);
  if (!isPremium) return null;
  return ref.watch(purchaseServiceProvider).getSubscriptionDetails();
});
