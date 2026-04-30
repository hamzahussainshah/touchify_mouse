import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Analytics so call sites have a stable API
/// and event names live in one place (typos in event names = lost data).
class Analytics {
  Analytics._();
  static final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Use as `navigatorObservers: [Analytics.observer]` on GoRouter / MaterialApp
  /// to auto-log `screen_view` events on every navigation.
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _fa);

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  static Future<void> appOpened() => _log('app_opened');
  static Future<void> setUserProperty(String name, String? value) =>
      _fa.setUserProperty(name: name, value: value);

  // ── Connection ────────────────────────────────────────────────────────────
  static Future<void> deviceConnected({required String method}) =>
      _log('device_connected', {'method': method}); // qr | mdns | manual

  static Future<void> deviceDisconnected({required String reason}) =>
      _log('device_disconnected', {'reason': reason});

  // ── Feature usage ─────────────────────────────────────────────────────────
  static Future<void> featureUsed(String feature) =>
      _log('feature_used', {'feature': feature}); // trackpad | keyboard | media | mic | speaker

  static Future<void> mediaAction(String action) =>
      _log('media_action', {'action': action}); // play_pause | next | previous …

  static Future<void> shareDesktopLink() => _log('share_desktop_link');

  // ── Settings / Pro ────────────────────────────────────────────────────────
  static Future<void> themeChanged(String theme) =>
      _log('theme_changed', {'theme': theme});

  static Future<void> proViewed() => _log('pro_viewed');
  static Future<void> proPurchased({required String sku}) =>
      _log('pro_purchased', {'sku': sku});

  // ── Internal ──────────────────────────────────────────────────────────────
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _fa.logEvent(name: name, parameters: params);
      if (kDebugMode) debugPrint('[Analytics] $name $params');
    } catch (e) {
      debugPrint('[Analytics] failed: $e');
    }
  }
}
