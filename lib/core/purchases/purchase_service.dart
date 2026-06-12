import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../prefs/prefs_repository.dart';
import 'purchase_config.dart';

/// Result of a purchase or restore attempt, in terms the UI can act on.
/// A user-cancelled purchase is [cancelled], not [error] — it isn't a failure.
enum PurchaseOutcome { success, cancelled, error }

/// The purchase layer the rest of the app talks to. Abstract so tests (and
/// later paywall prompts) can swap in a fake without touching the real SDK.
abstract class PurchaseService {
  /// Current premium status. Seeded from the on-device cache before any
  /// network call, then kept up to date by the store.
  bool get isPremium;

  /// Emits whenever [isPremium] changes.
  Stream<bool> get isPremiumStream;

  /// Configures the SDK. Safe to call once at startup; never throws.
  Future<void> init();

  /// Fetches one configured offering (paywall) by id, or null if unavailable.
  Future<Offering?> getOffering(String id);

  /// Attempts to buy [package]. Cancellation is reported, not thrown.
  Future<PurchaseOutcome> purchase(Package package);

  /// Restores previous purchases (e.g. new device / reinstall).
  Future<PurchaseOutcome> restorePurchases();

  /// Releases resources. Call when the owning scope is torn down.
  void dispose();
}

/// True on the platforms where the RevenueCat SDK ships (App Store / Play).
/// Windows, Linux, web and desktop dev builds are treated as unsupported and
/// get premium unlocked (CLAUDE.md §3 — those targets don't ship to users).
bool defaultPurchasesSupported() {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

/// RevenueCat-backed implementation. Every SDK call is wrapped so a network
/// failure or a placeholder API key never crashes or blocks the app — the
/// user simply continues with their cached (free, by default) status.
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(
    this._prefs, {
    bool? supported,
  }) : _supported = supported ?? defaultPurchasesSupported() {
    // Seed synchronously so providers have an answer on the very first frame.
    _isPremium = _supported ? _prefs.premiumCached : true;
  }

  final PrefsRepository _prefs;
  final bool _supported;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  late bool _isPremium;
  bool _configured = false;

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> get isPremiumStream => _controller.stream;

  String get _apiKey {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PurchaseConfig.googleApiKey;
      default:
        return PurchaseConfig.appleApiKey; // iOS + macOS
    }
  }

  @override
  Future<void> init() async {
    if (!_supported) {
      _setPremium(true);
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
      // Fires immediately with the latest CustomerInfo if one is cached.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
    } catch (e) {
      debugPrint('RevenueCat init failed (continuing with cached status): $e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active
        .containsKey(PurchaseConfig.premiumEntitlementId);
    _setPremium(active);
  }

  void _setPremium(bool value) {
    final changed = value != _isPremium;
    _isPremium = value;
    if (!_controller.isClosed) _controller.add(value);
    if (changed && _supported) {
      unawaited(_prefs.setPremiumCached(value));
    }
  }

  @override
  Future<Offering?> getOffering(String id) async {
    if (!_supported || !_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.getOffering(id);
    } catch (e) {
      debugPrint('getOffering($id) failed: $e');
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> purchase(Package package) async {
    if (!_supported) return PurchaseOutcome.error;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfo(result.customerInfo);
      return PurchaseOutcome.success;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      debugPrint('purchase failed: $e');
      return PurchaseOutcome.error;
    } catch (e) {
      debugPrint('purchase failed: $e');
      return PurchaseOutcome.error;
    }
  }

  @override
  Future<PurchaseOutcome> restorePurchases() async {
    if (!_supported) return PurchaseOutcome.success; // already premium
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfo(info);
      return PurchaseOutcome.success;
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
      return PurchaseOutcome.error;
    }
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
