# iOS Home-Screen Widget — Xcode setup (beginner guide)

This guide adds the "Daily Quote" widget to the iOS home screen. The Dart code
and the Swift widget code are already written — what's left can only be done
inside Xcode, and it takes about 15 minutes the first time. No prior Xcode or
Swift experience is needed; just follow each step in order.

> **You only do this once.** After the widget target exists and builds, you never
> repeat these steps. Routine `flutter run` / `flutter build` already include it.

---

## 0. What we're building (plain English)

A home-screen widget on iOS is a tiny separate program that lives next to the
app. iOS calls it an **App Extension**, and the kind that draws home-screen
widgets is a **Widget Extension**. It can't share memory with the app directly,
so the two talk through a shared mailbox called an **App Group**.

How our quote widget works:

- The Flutter app writes a 14-day list of quotes into the App Group mailbox every
  time it opens (`lib/core/widgetkit/home_widget_service.dart`).
- The Swift widget reads that mailbox and shows today's quote, rotating to the
  next one each midnight — even if the app is never opened.

The three names that must match across the app and the widget:

| What | Value | Where it lives |
|---|---|---|
| Widget target / `kind` | `VeganKitWidget` | Xcode target name + `kind` in Swift + `iOSName:` in Dart |
| App Group id | `group.io.develooper.vegankit` | both targets' Signing & Capabilities |
| Widget bundle id | `io.develooper.vegankit.VeganKitWidget` | the widget target's settings |

If any of these three disagree, the widget shows nothing. Keep them identical.

---

## 1. Before you start

- A Mac with **Xcode** installed (this guide matches Xcode 26.x).
- The app already builds: run `flutter run` once on a simulator or device to
  confirm, then close it.
- Open the iOS project the right way — **always the workspace, not the project**:

  ```
  cd vegan_motivation_app
  open ios/Runner.xcworkspace
  ```

  (`.xcworkspace` includes the Flutter plugins; `.xcodeproj` does not.)

---

## 2. Create the Widget Extension target

1. In Xcode's menu bar: **File → New → Target…**
2. In the search box type **Widget Extension**, select it, click **Next**.
3. Fill the form:
   - **Product Name:** `VeganKitWidget` — type it exactly. This becomes the
     widget's `kind` and must match the Dart `iOSName: 'VeganKitWidget'`.
   - **Team:** your Apple ID team (the same one Runner uses).
   - **Include Live Activity:** **uncheck** it (we don't use Live Activities).
   - **Include Control Widget** (if shown): **uncheck** it.
   - Leave "Project" as Runner and "Embed in Application" as Runner.
4. Click **Finish**.
5. Xcode pops up **"Activate 'VeganKitWidget' scheme?"** → click **Cancel** (keep
   the **Runner** scheme selected so you keep running the full app). Activating by
   accident is harmless — just switch the scheme back to **Runner** in the toolbar.

You now have a new `VeganKitWidget` group in the left sidebar.

---

## 3. Clean up the files Xcode generated

Xcode always drops in a sample widget plus extras. In the `VeganKitWidget` group
you'll see something like:

- `VeganKitWidget.swift` — a **sample** "emoji" widget (we replace its contents)
- `VeganKitWidgetBundle.swift` — has `@main` and lists several widgets
- `VeganKitWidgetControl.swift` — a Control Widget (delete)
- `VeganKitWidgetLiveActivity.swift` — a Live Activity (delete)
- `Info.plist`, `Assets.xcassets` — keep these

Do the following:

1. **Delete** `VeganKitWidgetControl.swift` and `VeganKitWidgetLiveActivity.swift`:
   right-click each → **Delete** → **Move to Trash**. We don't use them, and they
   reference features we didn't include.
2. **Open `VeganKitWidgetBundle.swift`.** It contains the app's single `@main`
   entry point and a list of widgets. Edit its body so it lists **only** our
   widget:

   ```swift
   import WidgetKit
   import SwiftUI

   @main
   struct VeganKitWidgetBundle: WidgetBundle {
       var body: some Widget {
           VeganKitWidget()
       }
   }
   ```

   > **Why this matters:** a Widget Extension may have **exactly one** `@main`.
   > The sample `VeganKitWidget.swift` you may have seen online sometimes carries
   > its own `@main` — our prepared version does **not**, so the only `@main` is
   > here in the Bundle. If Xcode ever complains *"'main' attribute can only apply
   > to one type"*, you have two `@main`s — remove the one that isn't in the
   > Bundle file.

---

## 4. Put our quote-widget code into `VeganKitWidget.swift`

Our real widget code (reads the App Group mailbox, renders the quote, rotates
daily) is stored in git. The sample that Xcode generated has overwritten the
working copy, so restore ours and keep using that file.

1. From a terminal in `vegan_motivation_app`, restore our version:

   ```
   git checkout -- ios/VeganKitWidget/VeganKitWidget.swift
   ```

   (If git reports the file isn't tracked at that path, the rename hasn't reached
   your checkout — run `git pull` first, then retry.)

2. Back in Xcode, open `VeganKitWidget.swift` and confirm it now contains the
   quote widget: a `struct VeganKitWidget: Widget` whose `kind` is
   `"VeganKitWidget"`, a timeline provider that reads the queue, and a view that
   draws `entry.text`. It should **not** mention emojis.
3. **Check target membership** (this is the #1 beginner trap): select
   `VeganKitWidget.swift`, open the right-hand **File Inspector** (top-right icon
   that looks like a page), and under **Target Membership** make sure
   **VeganKitWidget** is checked (and Runner is **not**). Repeat the check for
   `VeganKitWidgetBundle.swift`.

---

## 5. Add the App Group to BOTH targets

The app and the widget share data only if both belong to the same App Group.

1. Click the blue **Runner** project at the very top of the sidebar, then in the
   **TARGETS** list select **Runner**.
2. Open the **Signing & Capabilities** tab.
3. Click **+ Capability** (top-left of that tab), type **App Groups**, double-click
   it to add the section.
4. In the App Groups box, click **+** and add exactly:

   ```
   group.io.develooper.vegankit
   ```

   (Our prepared `ios/Runner/Runner.entitlements` already lists it. If Xcode made
   a brand-new entitlements file, either retype the group here or point
   **Build Settings → Code Signing Entitlements** for Runner at
   `Runner/Runner.entitlements`.)
5. Now select the **VeganKitWidget** target in the TARGETS list and repeat steps
   2–4 — same **App Groups** capability, the **same** `group.io.develooper.vegankit`.
   The prepared file for this side is `ios/VeganKitWidget/VeganKitWidget.entitlements`.

> Both checkboxes must show the **same** group, fully ticked. A mismatch here is
> the most common reason a widget stays blank.

---

## 6. Match the deployment target

1. With the **VeganKitWidget** target selected, open **General**.
2. Set **Minimum Deployments → iOS** to the same value as Runner (Runner is
   currently **iOS 17 or higher**). The widget uses `containerBackground(for:)`,
   which needs **iOS 17+**, so don't set it lower than 17.

---

## 7. Build and add the widget

1. In the toolbar, make sure the scheme is **Runner** (not VeganKitWidget), pick a
   simulator or your device, and press **▶ Run**.
2. When the app launches, **open it once** — that first launch is what fills the
   quote mailbox.
3. Send the app to the background (go to the home screen). **Long-press** an empty
   area of the home screen → tap **+** (top-left) → search **VeganKit** → pick the
   **Daily Quote** widget → **Add Widget**.

You should see today's quote on the home screen.

---

## 8. Verify it works

- The widget shows a real quote after the app has been opened once.
- Change the device's date forward by one day (Settings → General → Date & Time,
  turn off "Set Automatically"): the widget rotates to the next quote on its own,
  without opening the app. (It's driven by a WidgetKit timeline with one entry per
  local midnight.)

---

## 9. Troubleshooting

- **"'main' attribute can only apply to one type"** — you have two `@main`. Keep
  the one in `VeganKitWidgetBundle.swift` and remove any other. See step 3.
- **Widget not in the "Add Widget" list** — the target didn't build, or
  `VeganKitWidget.swift` isn't a member of the VeganKitWidget target. Re-check
  Target Membership (step 4.3) and that the project builds with no red errors.
- **Widget appears but is blank / says no quote** — App Group mismatch (step 5) or
  the app hasn't been opened yet (step 7.2). Confirm both targets list
  `group.io.develooper.vegankit` and that `kind` in Swift, the target name, and
  the Dart `iOSName:` are all `VeganKitWidget`.
- **"Cannot find type … in scope" about Control/LiveActivity** — you didn't delete
  the generated `VeganKitWidgetControl.swift` / `VeganKitWidgetLiveActivity.swift`,
  or the Bundle still references them. Delete those files and trim the Bundle to
  list only `VeganKitWidget()` (step 3).
- **Signing errors** — make sure the VeganKitWidget target uses the same **Team**
  as Runner under Signing & Capabilities.

---

## 10. How it works (reference)

`lib/core/widgetkit/home_widget_service.dart` writes a 14-day, date-indexed JSON
queue into the shared App Group `UserDefaults` under the key `quote_queue` every
time the app opens or the category mix changes. It calls
`HomeWidget.setAppGroupId('group.io.develooper.vegankit')` and refreshes via
`HomeWidget.updateWidget(iOSName: 'VeganKitWidget')`.

> We pin `home_widget: ^0.7.0`, whose API uses the **`iOSName:`** parameter. Newer
> 0.8+/0.9 releases rename this to `name:` — don't copy those snippets unless the
> pin in `pubspec.yaml` is deliberately bumped.

On the Swift side, the widget's `TimelineProvider` reads that queue and maps it to
one timeline entry per local midnight (`policy: .atEnd`), so the home screen keeps
rotating quotes for up to two weeks without the app being opened.
