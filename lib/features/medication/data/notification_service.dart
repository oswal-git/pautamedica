import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:timezone/data/latest.dart' as tz;

final StreamController<NotificationResponse> didReceiveLocalNotificationStream =
    StreamController<NotificationResponse>.broadcast();

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel', // id
      'Medication Reminders', // title
      description: 'Notifications for medication reminders', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      // sound: RawResourceAndroidNotificationSound('my_custom_sound'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    didReceiveLocalNotificationStream.add(notificationResponse);
  }

  Future<void> showNotification({
    required Dose dose,
    required String title,
    required String body,
  }) async {
    print("NotificationService: Attempting to show notification for ${dose.medicationName}");
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medication_channel', // Use the static channel ID
      'Medication Reminders', // Use the static channel name
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      dose.id.hashCode, // notification id
      title,
      body,
      platformChannelSpecifics,
      payload: dose.id,
    );
    print("NotificationService: Notification shown for ${dose.medicationName}");
  }

  Future<void> cancelNotification(String doseId) async {
    await flutterLocalNotificationsPlugin.cancel(doseId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
