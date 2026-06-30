import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
  if (kIsWeb || _initialized) return;

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _plugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // optional: gérer clic notif
    },
  );

  _initialized = true;
}

  // ─── Permission (Android 13+, iOS) ────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  // ─── Notification de fin de session ───────────────────────────────────────

  Future<void> showTimerCompleteNotification({
    required String modeName,
    required String nextMode,
  }) async {
    // Pas de notif native sur le web
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pomo_timer_channel',
      'Pomo Timer',
      channelDescription: 'Notifications de fin de session Pomodoro',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = _getTitleForMode(modeName);
    final String body = _getBodyForMode(modeName);

    await _plugin.show(
      _kNotifId,
      title,
      body,
      details,
    );
  }

  // ─── Annuler toutes les notifs ─────────────────────────────────────────────

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static const int _kNotifId = 42;

  String _getTitleForMode(String modeName) {
    switch (modeName) {
      case 'Focus':
        return '🍏Session Focus terminée !';
      case 'Short Break':
        return '☕ Pause courte terminée !';
      case 'Long Break':
        return '🌿 Grande pause terminée !';
      default:
        return '⏰ Session terminée !';
    }
  }

  String _getBodyForMode(String modeName) {
    switch (modeName) {
      case 'Focus':
        return 'Excellent travail ! C\'est l\'heure de la pause. 🎉';
      case 'Short Break':
      case 'Long Break':
        return 'La pause est terminée. Prêt pour une nouvelle session Focus ? 💪';
      default:
        return 'Session terminée, passez à la prochaine étape.';
    }
  }
}
