import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vegan_motivation_app/core/purchases/purchase_service.dart';

/// In-memory [PurchaseService] for tests — no real SDK, no network. Drive
/// premium changes with [emitPremium] and stub purchase/restore results.
///
/// Reusable by later paywall prompts: inject it via
/// `purchaseServiceProvider.overrideWithValue(FakePurchaseService(...))`.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({
    bool initialPremium = false,
    this.purchaseResult = PurchaseOutcome.success,
    this.restoreResult = PurchaseOutcome.success,
  }) : _isPremium = initialPremium;

  bool _isPremium;
  final _controller = StreamController<bool>.broadcast();

  /// What [purchase] returns. Set per test.
  PurchaseOutcome purchaseResult;

  /// What [restorePurchases] returns. Set per test.
  PurchaseOutcome restoreResult;

  /// Call counters, handy for asserting wiring in later prompts.
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
  Future<Offering?> getOffering(String id) async => null;

  @override
  Future<PurchaseOutcome> purchase(Package package) async {
    if (purchaseResult == PurchaseOutcome.success) emitPremium(true);
    return purchaseResult;
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async {
    restoreCalls++;
    if (restoreResult == PurchaseOutcome.success) emitPremium(true);
    return restoreResult;
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
