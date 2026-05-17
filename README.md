# Instally Flutter SDK

Track clicks, installs, and revenue from every link you share. See which links actually drive installs and revenue for your Flutter app. One SDK, both stores — no IDFA, no ATT prompt.

![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-black)
![Flutter](https://img.shields.io/badge/flutter-3.10%2B-blue)
![License](https://img.shields.io/badge/license-MIT-black)

**[Website](https://instally.io)** | **[Documentation](https://docs.instally.io)** | **[Blog](https://instally.io/blog)** | **[Sign Up Free](https://app.instally.io/signup)**

## Features

- Cross-platform iOS and Android support from a single Dart package
- High-accuracy attribution on both stores
- No IDFA, no ATT prompt, no GAID
- Per-link install and revenue tracking
- Real-time dashboard
- Webhook integrations with RevenueCat, Superwall, Adapty, Qonversion, and Stripe
- Minimal package size, no conditional platform imports

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  instally: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Configure

Call once in your `main()` or `initState()`:

```dart
import 'package:instally/instally.dart';

Instally.configure(appId: 'app_xxx', apiKey: 'key_xxx');
```

### 2. Track Installs

Call on every app launch. The SDK automatically ensures it only runs once per install:

```dart
final result = await Instally.trackInstall();
print('Matched: ${result.matched}');
```

### 3. Link User ID

Connect your user ID (e.g. RevenueCat, Qonversion) so server-side webhooks can attribute purchases:

```dart
await Instally.setUserId(Purchases.appUserID);
```

### 4. Track Purchases (Optional)

If you're not using a server-side integration, you can track purchases directly:

```dart
await Instally.trackPurchase(
  productId: 'premium_monthly',
  revenue: 9.99,
  currency: 'USD',
  transactionId: purchaseDetails.purchaseID,
);
```

## API Reference

| Method | Description |
|--------|-------------|
| `Instally.configure(appId:, apiKey:)` | Initialize the SDK |
| `Instally.trackInstall()` | Track install attribution (returns `Future<AttributionResult>`) |
| `Instally.trackPurchase(...)` | Track a purchase |
| `Instally.setUserId(userId)` | Link an external user ID |
| `Instally.resetForTesting()` | Clear cached attribution state during development testing |
| `Instally.isAttributed` | Whether this install was attributed to a link |
| `Instally.attributionId` | The attribution ID (null if not attributed) |

## Testing Attribution

Development builds are supported. For the cleanest test, click the tracking link
once on the same physical device you open the app on, then launch the app within
a few minutes.

Avoid repeated clicks before opening the app. Multiple recent unmatched clicks
from the same device or network can be treated as ambiguous and return
`matched=false`.

`trackInstall()` is cached per app install, including `matched=false` results.
When retrying on the same dev build, uninstall/reinstall the app or clear the SDK
cache in development:

```dart
if (kDebugMode) {
  await Instally.resetForTesting();
}
```

## FAQ

### Do I need to show an ATT prompt on iOS?

No. The SDK does not request the IDFA, so iOS does not require the ATT prompt.

### Does it work with RevenueCat or Stripe?

Yes. Call `Instally.setUserId(...)` with your subscription-platform user ID, then configure the Instally webhook. Purchases are automatically attributed to the link that drove the install. See the [RevenueCat integration guide](https://instally.io/blog/revenuecat-instally-integration).

### Does it work on iOS-only or Android-only Flutter apps?

Yes. The SDK no-ops on unsupported platforms (e.g., web, desktop).

### What's the package size?

Small — no native code beyond what Flutter ships by default on each platform.

### Where can I see my data?

Real-time dashboard at [app.instally.io](https://app.instally.io) — clicks, installs, revenue, per-link breakdown.

## Requirements

- Flutter 3.10+
- Dart 3.0+

## Learn More

- [How to Track App Installs in Flutter](https://instally.io/blog/how-to-track-app-installs-flutter) — full integration walkthrough
- [One Link for App Store and Google Play](https://instally.io/blog/one-link-app-store-google-play) — how single-URL routing works

## Resources

- [Instally Website](https://instally.io) — Track clicks, installs, and revenue from every link
- [Dashboard](https://app.instally.io) — Real-time analytics for your app installs
- [Documentation](https://docs.instally.io) — Full SDK docs and API reference
- [Pricing](https://instally.io/pricing) — Free tier available, no credit card required
- [Blog](https://instally.io/blog) — Guides on install tracking, IDFA, and more

### Other SDKs

- [iOS SDK](https://github.com/Instally-io/instally-ios-sdk)
- [Android SDK](https://github.com/Instally-io/instally-android-sdk)
- [React Native SDK](https://github.com/Instally-io/instally-react-native-sdk)

## License

MIT
