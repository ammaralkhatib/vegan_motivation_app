import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';

/// In-memory [PurchaseService] for tests — no real SDK, no network. Drive
/// premium changes with [emitPremium], stub purchase/restore results, and
/// script [getOffering] via [offerings].
///
/// Inject it with
/// `purchaseServiceProvider.overrideWithValue(FakePurchaseService(...))`.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    bool initialPremium = false,
    this.purchaseResult = PurchaseOutcome.success,
    this.restoreResult = PurchaseOutcome.success,
    this.restoreGrantsPremium = true,
    Map<String, Offering>? offerings,
  })  : _isPremium = initialPremium,
        offerings = offerings ?? const {};

  bool _isPremium;
  final _controller = StreamController<bool>.broadcast();

  /// What [purchase] returns. Set per test.
  PurchaseOutcome purchaseResult;

  /// What [restorePurchases] returns. Set per test.
  PurchaseOutcome restoreResult;

  /// Whether a successful [restorePurchases] also makes the user premium.
  /// Lets tests model "restored a subscription" vs "nothing to restore".
  bool restoreGrantsPremium;

  /// Offerings returned by [getOffering], keyed by id. Empty → null (the
  /// paywall's offline/retry state).
  final Map<String, Offering> offerings;

  /// Call counters, handy for asserting wiring.
  int initCalls = 0;
  int restoreCalls = 0;

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> get isPremiumStream => _controller.stream;

  /// Simulate the store reporting a new premium status.
  void emitPremium(bool value) {
    _isPremium = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<Offering?> getOffering(String id) async => offerings[id];

  @override
  Future<PurchaseOutcome> purchase(Package package) async {
    if (purchaseResult == PurchaseOutcome.success) emitPremium(true);
    return purchaseResult;
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async {
    restoreCalls++;
    if (restoreResult == PurchaseOutcome.success && restoreGrantsPremium) {
      emitPremium(true);
    }
    return restoreResult;
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
