// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialisation
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInitSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification cliquée: ${details.payload}');
      },
    );

    debugPrint("✅ NotificationService initialisé");
  }

  /// Notification immédiate
  static Future<void> showNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alumni_channel',
      'Alumni Notifications',
      channelDescription: 'Notifications automatiques',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, platformDetails);
    debugPrint("📣 Notification immédiate affichée: $title");
  }

  /// Notification planifiée
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final scheduledDate = tz.TZDateTime.from(date, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("⚠️ Date passée, notification non planifiée: $title");
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'alumni_channel',
      'Alumni Notifications',
      channelDescription: 'Notifications automatiques',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ✅ correct
      );
      debugPrint("🕒 Notification planifiée: $title à $scheduledDate");
    } catch (e) {
      debugPrint("⚠️ Impossible de planifier la notification exacte: $e");
    }
  }

  /// Annuler une notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint("❌ Notification annulée ID=$id");
  }

  /// Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("❌ Toutes les notifications annulées");
  }
}
