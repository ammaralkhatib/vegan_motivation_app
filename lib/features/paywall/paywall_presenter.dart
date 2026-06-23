import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/notifications/trial_reminder.dart';
import '../../core/purchases/purchase_config.dart';
import '../../core/purchases/purchase_providers.dart';
import '../../core/purchases/purchase_service.dart';
import 'paywall_data.dart';

/// Outcome of presenting a hosted paywall, in terms the app acts on.
/// RevenueCat's `error` and `notPresented` both collapse to [notPresented] —
/// both mean "no purchase happened, just carry on".
enum PaywallPresentResult { purchased, restored, cancelled, notPresented }

/// Presents the RevenueCat hosted paywall for a [PaywallVariant]. Takes **no**
/// [BuildContext] — RevenueCat presents its paywall natively, on top of the app.
abstract class PaywallPresenter {
  Future<PaywallPresentResult> present(PaywallVariant variant);
}

/// Real implementation: looks the offering up through the existing
/// [PurchaseService] (no second RevenueCat config path), then shows
/// RevenueCat's hosted paywall for it.
class RevenueCatPaywallPresenter implements PaywallPresenter {
  RevenueCatPaywallPresenter(this._service);

  final PurchaseService _service;

  @override
  Future<PaywallPresentResult> present(PaywallVariant variant) async {
    final offering = await _service.getOffering(variant.offeringId);
    // No offering (offline, placeholder keys, missing dashboard setup) → just
    // continue, as if nothing was shown.
    if (offering == null) return PaywallPresentResult.notPresented;

    // displayCloseButton: true is required — Apple 5.6 says the user must
    // always be able to dismiss the paywall.
    final result = await RevenueCatUI.presentPaywall(
      offering: offering,
      displayCloseButton: true,
    );

    final mapped = switch (result) {
      PaywallResult.purchased => PaywallPresentResult.purchased,
      PaywallResult.restored => PaywallPresentResult.restored,
      PaywallResult.cancelled => PaywallPresentResult.cancelled,
      PaywallResult.error => PaywallPresentResult.notPresented,
      PaywallResult.notPresented => PaywallPresentResult.notPresented,
    };

    if (mapped == PaywallPresentResult.purchased) {
      await _scheduleTrialReminderIfNeeded();
    }
    return mapped;
  }

  /// Mirrors the old `paywall_screen._buy`: if the just-bought product is the
  /// 7-day-trial product, schedule the "trial ends tomorrow" reminder. The
  /// product id comes from the active premium entitlement in CustomerInfo.
  /// Wrapped in try/catch so a reminder failure never breaks the flow.
  Future<void> _scheduleTrialReminderIfNeeded() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final productId = info
          .entitlements.active[PurchaseConfig.premiumEntitlementId]
          ?.productIdentifier;
      if (productId != null && shouldScheduleTrialReminder(productId)) {
        await NotificationService.instance.scheduleTrialEndReminder(
          trialReminderFireTime(DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('trial reminder scheduling failed (continuing): $e');
    }
  }
}

/// The app's paywall presenter. Overridable in tests with a fake.
final paywallPresenterProvider = Provider<PaywallPresenter>(
  (ref) => RevenueCatPaywallPresenter(ref.read(purchaseServiceProvider)),
);
