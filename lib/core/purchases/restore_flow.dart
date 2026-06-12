import 'purchase_service.dart';

/// Outcome of a "Restore purchases" attempt, in terms the UI can act on.
enum RestoreResult {
  /// Premium is active after restoring — welcome them back and close.
  restored,

  /// Restore succeeded but found nothing to unlock.
  noneFound,

  /// Restore failed (e.g. network/store error).
  error,
}

/// Runs a restore and classifies the result. Reads the service's [isPremium]
/// directly (updated synchronously by the customer-info listener) rather than a
/// provider, so the answer is correct the instant the call returns. Shared by
/// the paywall's restore button and the Settings restore row.
Future<RestoreResult> performRestore(PurchaseService service) async {
  final outcome = await service.restorePurchases();
  if (service.isPremium) return RestoreResult.restored;
  return outcome == PurchaseOutcome.error
      ? RestoreResult.error
      : RestoreResult.noneFound;
}

/// User-facing message for a [RestoreResult].
String restoreMessage(RestoreResult result) => switch (result) {
      RestoreResult.restored => 'Welcome back!',
      RestoreResult.noneFound => 'No previous purchase found.',
      RestoreResult.error => 'Something went wrong — please try again.',
    };
