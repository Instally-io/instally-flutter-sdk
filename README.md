# Instally Flutter SDK

Track clicks, installs, and revenue from every link. Lightweight install tracking for Flutter apps.

[instally.io](https://instally.io)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  instally: ^1.0.0
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
| `Instally.isAttributed` | Whether this install was attributed to a link |
| `Instally.attributionId` | The attribution ID (null if not attributed) |

## Requirements

- Flutter 3.10+
- Dart 3.0+

## License

MIT
