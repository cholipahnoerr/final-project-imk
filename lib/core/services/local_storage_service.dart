import 'package:hive_flutter/hive_flutter.dart';

abstract class LocalStorageService {
  static late Box _prefs;
  static late Box _cache;

  static Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await Hive.openBox('hayyarabic_prefs');
    _cache = await Hive.openBox('hayyarabic_cache');
  }

  // ── Notification preferences ─────────────────────
  static bool get notificationsEnabled =>
      _prefs.get('notifications_enabled', defaultValue: true) as bool;

  static Future<void> setNotificationsEnabled(bool value) =>
      _prefs.put('notifications_enabled', value);

  static String get notificationTime =>
      _prefs.get('notification_time', defaultValue: '20:00') as String;

  static Future<void> setNotificationTime(String hhmm) =>
      _prefs.put('notification_time', hhmm);

  // ── General cache ─────────────────────────────────
  static Future<void> put(String key, dynamic value) => _cache.put(key, value);

  static T? get<T>(String key) => _cache.get(key) as T?;

  static Future<void> clear() => _cache.clear();
}
