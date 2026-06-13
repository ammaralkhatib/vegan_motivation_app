/// The trial-end reminder: scheduled when the 7-day-trial product is bought,
/// so the user gets a heads-up the day before they're charged.
library;

/// RevenueCat product id for the full-price yearly product that carries the
/// 7-day free trial (CLAUDE.md §3). Only this product triggers the reminder.
const String trialProductId = 'vegankit_yearly_full';

/// Reserved notification id for the trial reminder. Sits far above the daily
/// quote ids (spread < ~1.6M, meal mode 100M–101.6M) so it can never collide.
const int trialReminderNotificationId = 900000001;

/// Whether a just-purchased product should trigger the trial-end reminder.
/// True only for the trial product — never the 50%/80% discount products.
bool shouldScheduleTrialReminder(String productId) =>
    productId == trialProductId;

/// When the reminder fires: 6 days after purchase (the trial is 7 days, so this
/// lands "tomorrow" relative to the trial ending).
DateTime trialReminderFireTime(DateTime purchasedAt) =>
    purchasedAt.add(const Duration(days: 6));
