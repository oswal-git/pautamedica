import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final StreamController<NotificationResponse> didReceiveLocalNotificationStream =
    StreamController<NotificationResponse>.broadcast();

class NotificationService {
  final _logger = Logger();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService();

  Future<void> init() async {
    tz_data.initializeTimeZones();

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

    final InitializationSettings initializationSettings =
        InitializationSettings(
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
    _logger.i(
        "NotificationService: Attempting to show notification for ${dose.medicationName}");
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel', // Use the static channel ID
      'Medication Reminders', // Use the static channel name
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
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
    _logger.i(
        "NotificationService: Notification shown for ${dose.medicationName}");
  }

  Future<void> scheduleNotification({
    required Dose dose,
    required String title,
    required String body,
  }) async {
    _logger.i(
        "NotificationService: Scheduling exact notification for ${dose.medicationName} at ${dose.time}");

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final scheduledDate = tz.TZDateTime.from(dose.time, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      _logger.w(
          "NotificationService: Cannot schedule notification in the past for ${dose.medicationName}");
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      dose.id.hashCode,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: dose.id,
    );
    _logger.i(
        "NotificationService: Notification scheduled for ${dose.medicationName} at $scheduledDate");
  }

  Future<void> cancelNotification(String doseId) async {
    await flutterLocalNotificationsPlugin.cancel(doseId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
