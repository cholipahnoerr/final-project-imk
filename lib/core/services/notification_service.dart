import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_storage_service.dart';

abstract class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _streakChannelId = 'streak_reminder';
  static const _streakChannelName = 'Pengingat Streak';
  static const _streakNotifId = 1;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleStreakReminder() async {
    if (!LocalStorageService.notificationsEnabled) return;
    await _plugin.periodicallyShow(
      _streakNotifId,
      'Jangan lupa belajar hari ini! 🔥',
      'Streak kamu menunggu. Yuk lanjutkan pembelajaran Arabic-mu!',
      RepeatInterval.daily,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _streakChannelId,
          _streakChannelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(
            'Streak kamu menunggu. Yuk lanjutkan pembelajaran Arabic-mu!',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakNotifId);
  }

  static Future<void> showStreakBrokenNotif(int streakDays) async {
    await _plugin.show(
      2,
      'Streak kamu terputus 😢',
      'Streak $streakDays hari kamu berakhir. Mulai lagi hari ini!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _streakChannelId,
          _streakChannelName,
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  static Future<void> showAchievementUnlocked(String label) async {
    await _plugin.show(
      3,
      '🏆 Pencapaian Baru!',
      'Kamu berhasil membuka: $label',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Pencapaian',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
