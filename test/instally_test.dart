import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:instally/instally.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Instally.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('configure', () {
    test('sets up SDK without error', () {
      Instally.configure(appId: 'app_test', apiKey: 'key_test');
      // No exception = success
    });
  });

  group('trackInstall', () {
    test('throws if not configured', () {
      expect(() => Instally.trackInstall(), throwsStateError);
    });

    test('returns cached result on second call', () async {
      SharedPreferences.setMockInitialValues({
        'instally_tracked': true,
        'instally_matched': true,
        'instally_attribution_id': 'attr_123',
      });

      Instally.configure(appId: 'app_test', apiKey: 'key_test');

      final result = await Instally.trackInstall();
      expect(result.matched, true);
      expect(result.attributionId, 'attr_123');
      expect(result.method, 'cached');
    });

    test('calls API and returns result', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/v1/attribution'));
        expect(request.headers['X-API-Key'], 'key_test');
        expect(request.headers['X-App-ID'], 'app_test');

        return http.Response(
          jsonEncode({
            'matched': true,
            'attribution_id': 'attr_456',
            'confidence': 0.95,
            'method': 'fingerprint',
            'click_id': 'click_789',
          }),
          200,
        );
      });

      Instally.configure(appId: 'app_test', apiKey: 'key_test');
      Instally.setHttpClient(mockClient);
      Instally.setDeviceInfoOverride(() => {
        return {
          'platform': 'ios',
          'device_model': 'test',
          'os_version': '17.0',
          'screen_width': 390,
          'screen_height': 844,
          'timezone': 'UTC',
          'language': 'en',
        };
      });

      final result = await Instally.trackInstall();
      expect(result.matched, true);
      expect(result.attributionId, 'attr_456');
      expect(result.confidence, 0.95);
      expect(result.method, 'fingerprint');
      expect(result.clickId, 'click_789');

      // Verify persisted
      expect(Instally.isAttributed, true);
      expect(Instally.attributionId, 'attr_456');
    });
  });

  group('trackPurchase', () {
    test('throws if not configured', () {
      expect(
        () => Instally.trackPurchase(productId: 'test', revenue: 1.0),
        throwsStateError,
      );
    });
  });

  group('setUserId', () {
    test('throws if not configured', () {
      expect(() => Instally.setUserId('user_123'), throwsStateError);
    });
  });

  group('isAttributed', () {
    test('defaults to false', () {
      expect(Instally.isAttributed, false);
    });
  });

  group('attributionId', () {
    test('defaults to null', () {
      expect(Instally.attributionId, null);
    });
  });
}
