/// Instally Flutter SDK
/// Track clicks, installs, and revenue from every link.
/// https://instally.io
library instally;

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Instally {
  static String? _appId;
  static String? _apiKey;
  static String _apiBase =
      'https://us-central1-instally-5f6fd.cloudfunctions.net/api';
  static bool _isConfigured = false;
  static const String _sdkVersion = '1.0.0';

  // Cached values (loaded from SharedPreferences)
  static bool _isAttributed = false;
  static String? _attributionId;

  // Injectable HTTP client for testing
  static http.Client? _httpClient;

  // Injectable device info resolver for testing
  static Map<String, dynamic> Function()? _deviceInfoOverride;

  /// Configure Instally with your app credentials.
  /// Call once in your main() or initState().
  ///
  /// ```dart
  /// Instally.configure(appId: 'app_xxx', apiKey: 'key_xxx');
  /// ```
  static void configure({required String appId, required String apiKey}) {
    _appId = appId;
    _apiKey = apiKey;
    _isConfigured = true;
  }

  /// Override the API base URL (for testing).
  static void setAPIBase(String url) {
    _apiBase = url;
  }

  /// Override the HTTP client (for testing).
  @visibleForTesting
  static void setHttpClient(http.Client? client) {
    _httpClient = client;
  }

  /// Override device info resolution (for testing).
  @visibleForTesting
  static void setDeviceInfoOverride(Map<String, dynamic> Function()? resolver) {
    _deviceInfoOverride = resolver;
  }

  /// Reset all state (for testing).
  @visibleForTesting
  static void reset() {
    _appId = null;
    _apiKey = null;
    _apiBase = 'https://us-central1-instally-5f6fd.cloudfunctions.net/api';
    _isConfigured = false;
    _isAttributed = false;
    _attributionId = null;
    _httpClient = null;
    _deviceInfoOverride = null;
  }

  /// Track app install attribution. Call once on first launch, after configure().
  /// Automatically runs only once per install — safe to call on every launch.
  ///
  /// ```dart
  /// final result = await Instally.trackInstall();
  /// print('Matched: ${result.matched}');
  /// ```
  static Future<AttributionResult> trackInstall() async {
    if (!_isConfigured) {
      throw StateError('Call Instally.configure() before trackInstall()');
    }

    final prefs = await SharedPreferences.getInstance();

    // Load cached values into memory
    _isAttributed = prefs.getBool('instally_matched') ?? false;
    _attributionId = prefs.getString('instally_attribution_id');

    if (prefs.getBool('instally_tracked') ?? false) {
      return AttributionResult(
        matched: _isAttributed,
        attributionId: _attributionId,
        confidence: 0,
        method: 'cached',
      );
    }

    final deviceInfo = _deviceInfoOverride != null
        ? _deviceInfoOverride!()
        : {
            'platform': Platform.isIOS ? 'ios' : 'android',
            'device_model': Platform.localHostname,
            'os_version': Platform.operatingSystemVersion,
            'screen_width': PlatformDispatcher
                .instance.views.first.physicalSize.width
                .toInt(),
            'screen_height': PlatformDispatcher
                .instance.views.first.physicalSize.height
                .toInt(),
            'timezone': DateTime.now().timeZoneName,
            'language': PlatformDispatcher.instance.locale.languageCode,
          };

    final payload = {
      'app_id': _appId,
      ...deviceInfo,
      'sdk_version': _sdkVersion,
    };

    try {
      final json = await _post('/v1/attribution', payload);
      final result = AttributionResult(
        matched: json['matched'] ?? false,
        attributionId: json['attribution_id'],
        confidence: (json['confidence'] ?? 0).toDouble(),
        method: json['method'] ?? 'unknown',
        clickId: json['click_id'],
      );

      // Persist
      await prefs.setBool('instally_tracked', true);
      await prefs.setBool('instally_matched', result.matched);
      if (result.attributionId != null) {
        await prefs.setString(
            'instally_attribution_id', result.attributionId!);
      }

      // Update in-memory cache
      _isAttributed = result.matched;
      _attributionId = result.attributionId;

      return result;
    } catch (e) {
      // Don't mark as tracked so it retries next launch
      return AttributionResult(
        matched: false,
        attributionId: null,
        confidence: 0,
        method: 'error',
      );
    }
  }

  /// Track an in-app purchase. Call after every successful purchase.
  ///
  /// ```dart
  /// await Instally.trackPurchase(
  ///   productId: 'premium_monthly',
  ///   revenue: 9.99,
  ///   currency: 'USD',
  ///   transactionId: purchaseDetails.purchaseID,
  /// );
  /// ```
  static Future<void> trackPurchase({
    required String productId,
    required double revenue,
    String currency = 'USD',
    String? transactionId,
  }) async {
    if (!_isConfigured) {
      throw StateError('Call Instally.configure() before trackPurchase()');
    }

    final prefs = await SharedPreferences.getInstance();
    final attrId =
        _attributionId ?? prefs.getString('instally_attribution_id');
    if (attrId == null) return;

    final payload = {
      'app_id': _appId,
      'attribution_id': attrId,
      'product_id': productId,
      'revenue': revenue,
      'currency': currency,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'sdk_version': _sdkVersion,
      if (transactionId != null) 'transaction_id': transactionId,
    };

    await _post('/v1/purchases', payload);
  }

  /// Link an external user ID (e.g. RevenueCat appUserID) to this install's attribution.
  /// This allows server-side integrations (webhooks) to attribute purchases automatically.
  ///
  /// ```dart
  /// await Instally.setUserId(Purchases.appUserID);
  /// ```
  static Future<void> setUserId(String userId) async {
    if (!_isConfigured) {
      throw StateError('Call Instally.configure() before setUserId()');
    }

    final prefs = await SharedPreferences.getInstance();
    final attrId =
        _attributionId ?? prefs.getString('instally_attribution_id');
    if (attrId == null) return;

    final payload = {
      'app_id': _appId,
      'attribution_id': attrId,
      'user_id': userId,
      'sdk_version': _sdkVersion,
    };

    await _post('/v1/user-id', payload);
  }

  /// Whether this install was attributed to a link.
  /// Updated after [trackInstall] completes.
  static bool get isAttributed => _isAttributed;

  /// The attribution ID for this install, or null if not attributed.
  /// Updated after [trackInstall] completes.
  static String? get attributionId => _attributionId;

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_apiBase$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': _apiKey ?? '',
              'X-App-ID': _appId ?? '',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } finally {
      // Only close if we created it (not injected)
      if (_httpClient == null) {
        client.close();
      }
    }
  }
}

/// Result of install attribution.
class AttributionResult {
  final bool matched;
  final String? attributionId;
  final double confidence;
  final String method;
  final String? clickId;

  AttributionResult({
    required this.matched,
    this.attributionId,
    required this.confidence,
    required this.method,
    this.clickId,
  });
}
