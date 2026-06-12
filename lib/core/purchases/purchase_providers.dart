import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchase_service.dart';

/// The app's purchase layer. Created in main() and provided via override,
/// mirroring [prefsProvider]/[databaseProvider]. Tests override it with a
/// fake.
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => throw UnimplementedError('purchaseServiceProvider must be overridden'),
);

/// Whether the user currently has premium. Seeded from the service's cached
/// value (so it's correct on the first frame, offline) and updated live as the
/// store reports changes. Read this everywhere feature gating is needed.
class PremiumStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    final service = ref.watch(purchaseServiceProvider);
    final sub = service.isPremiumStream.listen((value) => state = value);
    ref.onDispose(sub.cancel);
    return service.isPremium;
  }
}

final isPremiumProvider =
    NotifierProvider<PremiumStatusNotifier, bool>(PremiumStatusNotifier.new);
