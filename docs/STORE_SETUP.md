# VeganKit Premium — Store & RevenueCat Setup Guide

Step-by-step guide for setting up the subscriptions in **App Store Connect**
(Apple), **Google Play Console**, and the **RevenueCat dashboard**. The app
code is already done — after this guide, paste the two API keys into the app
and everything goes live.

Websites change their buttons sometimes, so a label may differ slightly — but
the order of steps stays the same.

---

## The big picture

You are creating the same 3 yearly subscriptions in both stores, then telling
RevenueCat about them:

| What the user sees | Apple product ID | Google product ID | Price |
|---|---|---|---|
| Full price + 7-day free trial | `veggie_yearly_full` | `veggie_yearly_full` (base plan `yearly`) | $49.99/year |
| 50% off | `veggie_yearly_50` | `veggie_yearly_50` (base plan `yearly`) | $24.99/year |
| 80% off "last chance" | `veggie_yearly_80` | `veggie_yearly_80` (base plan `yearly`) | $9.99/year |

In RevenueCat these connect to:

- **1 entitlement:** `premium` (the on/off switch the app checks)
- **3 offerings** (one per paywall): `onboarding`, `default`, `discount`

⚠️ **Type these IDs exactly** — lowercase, with underscores. The app code
looks for these exact names (`lib/core/purchases/purchase_config.dart`).

---

## Part 0 — Before you start

- [ ] **Apple Developer account** ($99/year) at https://developer.apple.com
- [ ] In App Store Connect → **Business** (or "Agreements, Tax, and
      Banking"): the **Paid Apps agreement** must be signed, with bank and tax
      info filled in. Subscriptions cannot be created without this.
- [ ] **Google Play developer account** ($25 once) at
      https://play.google.com/console
- [ ] In Play Console: a **payments profile** linked (Settings → Payments
      profile). Same reason.
- [ ] The app must exist in both consoles (created as an app entry). For Play,
      you must also **upload a build** (internal testing is enough) before
      subscriptions can be tested — the build needs the BILLING permission,
      which the `purchases_flutter` plugin already adds.

---

## Part 1 — RevenueCat: project and apps

1. Sign up at https://app.revenuecat.com (free until the app earns real money).
2. Create a **Project** → name it `VeganKit`.
3. In the project, go to **Apps** (Project settings → Apps) → **+ New app**:
   - **App Store**: bundle ID `io.develooper.vegankit`.
   - **Play Store**: package name `io.develooper.vegankit`.
4. Don't worry about the credential fields yet — Parts 2 and 3 give you the
   things to paste in here.

---

## Part 2 — App Store Connect (Apple)

### 2a. Create the subscription group

1. Go to https://appstoreconnect.apple.com → **My Apps** → VeganKit.
2. In the left menu: **Monetization → Subscriptions**.
3. Click **Create** under Subscription Groups → name it `VeganKit Premium`.
   (A group = subscriptions a user can switch between. All 3 go in this one
   group, so a user can only have one at a time — which is what we want.)

### 2b. Create the 3 subscriptions

For each row of the table above, inside the group click **Create**:

1. **Reference name:** e.g. `VeganKit Yearly Full` (only you see this).
2. **Product ID:** exactly `veggie_yearly_full` / `veggie_yearly_50` /
   `veggie_yearly_80`. ⚠️ Cannot be changed later.
3. **Subscription duration:** 1 year.
4. **Price:** click **Add Subscription Price** → pick USA → $49.99 / $24.99 /
   $9.99. Apple fills in other countries automatically — accept the defaults.
5. **Localization:** add an English display name + short description, e.g.
   "VeganKit Premium — all categories, full quote library."
6. **Review information:** add a screenshot of your paywall (any size Apple
   accepts; this is only for Apple's reviewers) — you can do this later, but
   it's required before app review.

### 2c. Add the 7-day free trial (only on the full-price one)

1. Open `veggie_yearly_full` → **Subscription Prices** →
   **Introductory Offers** (click **+** / "Set Up Introductory Offer").
2. Countries: all. Start/end date: no end date.
3. Type: **Free trial**, duration: **1 week**. Save.
4. Do **not** add trials to the 50% and 80% products.

### 2d. Give RevenueCat access to Apple

Two things to set up in RevenueCat's App Store app settings (RevenueCat shows
help text next to each field):

1. **In-App Purchase Key:** App Store Connect → **Users and Access** →
   **Integrations** → **In-App Purchase** → generate a key → download the
   `.p8` file → upload it in RevenueCat (with its Key ID and Issuer ID).
2. **App-Specific Shared Secret:** in App Store Connect under your app →
   General → App Information (or under Subscriptions) → generate/view shared
   secret → copy it into RevenueCat.

---

## Part 3 — Google Play Console

### 3a. Create the 3 subscriptions

1. Go to https://play.google.com/console → VeganKit app.
2. Left menu: **Monetize → Products → Subscriptions** → **Create
   subscription**.
3. **Product ID:** exactly `veggie_yearly_full` (then `_50`, `_80`).
   ⚠️ Cannot be changed later. **Name:** e.g. "VeganKit Premium (Full)".
4. Inside the new subscription, click **Add base plan**:
   - **Base plan ID:** `yearly` ⚠️ (Google forbids underscores here — use
     exactly `yearly`, with no prefix).
   - Type: auto-renewing, billing period: **yearly**.
   - **Price:** set USA to $49.99 / $24.99 / $9.99 → use "Set prices" to let
     Google convert other countries.
   - **Activate** the base plan (it starts as a draft — don't forget this).
5. Repeat for all 3 subscriptions.

### 3b. Add the 7-day free trial (only on the full-price one)

1. Open `veggie_yearly_full` → base plan `yearly` → **Add offer**.
2. **Offer ID:** `free-trial` (hyphens, not underscores).
3. Eligibility: **New customer acquisition** → "Never had this subscription".
4. Add phase: **Free trial**, 7 days. Save and **Activate** the offer.

### 3c. Give RevenueCat access to Google

RevenueCat needs a "service account" (a robot login) to check purchases:

1. In RevenueCat → your Play Store app settings, follow the **"Create a
   service credentials JSON"** guide link. In short: in Google Cloud Console
   you create a service account, give it access in Play Console (**Users and
   permissions** → invite the service account email with "View financial
   data" + "Manage orders and subscriptions"), and download a JSON key file.
2. Upload that JSON in RevenueCat.
3. Note: Google credentials can take **up to ~36 hours** to start working.
   Set this up first, then do other parts while you wait.

---

## Part 4 — RevenueCat: products, entitlement, offerings

### 4a. Import the products

1. RevenueCat → **Product catalog** (or "Products") → **+ New** /
   **Import**. If the store credentials work, RevenueCat can import them
   automatically — otherwise add manually:
   - Apple products: `veggie_yearly_full`, `veggie_yearly_50`,
     `veggie_yearly_80`.
   - Google products: same IDs, each with base plan `yearly` (RevenueCat
     shows them as `veggie_yearly_full:yearly` etc. — that's normal).

### 4b. Create the entitlement

1. **Entitlements** → **+ New** → identifier: exactly `premium`.
2. Open it → **Attach products** → attach **all 6** products (3 Apple +
   3 Google). Buying any of them switches `premium` on — that's the only
   thing the app checks.

### 4c. Create the 3 offerings

**Offerings** → **+ New**, three times:

| Offering identifier | Add one package | Containing (Apple + Google) |
|---|---|---|
| `onboarding` | type **Annual** | `veggie_yearly_full` (+ `:yearly`) |
| `default` | type **Annual** | `veggie_yearly_50` (+ `:yearly`) |
| `discount` | type **Annual** | `veggie_yearly_80` (+ `:yearly`) |

⚠️ Identifiers exactly as written — the app asks for these by name. For the
Google product inside `onboarding`, make sure the **free-trial offer** is the
one served (RevenueCat picks the best eligible offer by default — the
default "offer selection" behavior is fine).

The "Current" default offering doesn't matter much for us (the app asks for
each offering by name), but set `default` as current to be tidy.

---

## Part 5 — API keys into the app

1. RevenueCat → Project settings → **API keys**.
2. Copy the two **public SDK keys**: one starts with `appl_`, one with
   `goog_`.
3. Send them to Planning Claude in Cowork — a tiny prompt will paste them
   into `lib/core/purchases/purchase_config.dart`. (They are public keys —
   safe to have inside the app.)

---

## Part 6 — Test it (no real money)

**iPhone (sandbox):**

1. App Store Connect → **Users and Access** → **Sandbox** → create a sandbox
   tester account (a fake Apple ID, e.g. ammar.test1@icloud.com).
2. On a real iPhone: Settings → App Store → scroll down → **Sandbox Account**
   → sign in with the tester.
3. Run the app from your machine (`flutter run` on the device). Go through
   onboarding → the trial paywall should show **real prices**.
4. Buy the trial — sandbox purchases are free and renew fast (a sandbox
   "year" is ~1 hour, so you can also see expiry behavior quickly).
5. Check: all 6 categories unlock, the premium row disappears from Settings,
   and the purchase appears in the RevenueCat dashboard ("Recent activity").

**Android (license testing):**

1. Play Console → **Settings** → **License testing** → add your own Gmail
   address as a license tester.
2. Upload the app to the **Internal testing** track (Release → Testing →
   Internal testing) and add yourself as a tester, install via the opt-in
   link. (Direct `flutter run` builds can also work for billing once the app
   is on a track, but the opt-in install is the reliable way.)
3. Same checks as on iPhone. Test purchases as a license tester are free and
   renew fast.

**Also test:** delete + reinstall the app → Settings → **Restore purchases**
→ should say "Welcome back!" and unlock premium.

---

## Checklist (the short version)

- [ ] Part 0: agreements + payment profiles signed in both consoles
- [ ] Part 1: RevenueCat project `VeganKit` with both apps
- [ ] Part 3c first (it's slow): Google service credentials JSON uploaded
- [ ] Part 2: 3 Apple subscriptions + trial + In-App Purchase Key + shared secret
- [ ] Part 3: 3 Google subscriptions (base plan `yearly`, activated!) + trial offer
- [ ] Part 4: products imported, entitlement `premium` with all 6, offerings
      `onboarding` / `default` / `discount`
- [ ] Part 5: `appl_…` and `goog_…` keys sent to Planning Claude
- [ ] Part 6: sandbox purchase works on iPhone + Android, restore works
