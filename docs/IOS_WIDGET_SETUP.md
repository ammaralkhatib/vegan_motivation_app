# iOS Home-Screen Widget — one-time Xcode setup

The Dart side and all Swift sources are ready. Creating a Widget Extension
*target* can only be done in Xcode (~5 minutes):

## Steps

1. `open ios/Runner.xcworkspace`
2. **File → New → Target… → Widget Extension**
   - Product Name: `VeggieWidget` (must match exactly — the Dart side calls
     `HomeWidget.updateWidget(iOSName: 'VeggieWidget')`)
   - Bundle id should become `com.ammarkhatib.veggie.VeggieWidget`
   - Uncheck "Include Configuration App Intent" (we use a StaticConfiguration)
   - When asked, do NOT activate the scheme for "Run" — keep Runner as the
     main scheme. (Activating is also fine, just switch back.)
3. Xcode generates a `VeggieWidget/` group with boilerplate Swift files.
   **Delete the generated `.swift` files** and drag in the prepared
   [`ios/VeggieWidget/VeggieWidget.swift`](VeggieWidget.swift) (check
   "VeggieWidget" target membership).
4. **App Groups** (both targets):
   - Runner target → Signing & Capabilities → + Capability → App Groups →
     add `group.com.ammarkhatib.veggie`
     (the prepared `ios/Runner/Runner.entitlements` already contains it; if
     Xcode created a new entitlements file, merge or point Code Signing
     Entitlements at the prepared one)
   - VeggieWidget target → same capability, same group
     (prepared file: `ios/VeggieWidget/VeggieWidget.entitlements`)
5. Set the widget target's iOS Deployment Target to match Runner (e.g. 17.0;
   `containerBackground(for:)` needs iOS 17+).
6. Build & run Runner on a device/simulator, open the app once (this writes
   the quote queue), then long-press the home screen → add the
   "Daily Quote" widget.

## Verify

- Widget shows today's quote after the app has been opened once.
- Advance the device date by one day → the widget rotates to the next quote
  without opening the app (WidgetKit timeline, one entry per midnight).

## How it works

`lib/core/widgetkit/home_widget_service.dart` writes a 14-day, date-indexed
JSON queue into the shared App Group UserDefaults under `quote_queue` every
time the app opens or the category mix changes. The widget's
`TimelineProvider` maps that queue to one timeline entry per local midnight
(`policy: .atEnd`), so it keeps rotating for up to two weeks without the app.
