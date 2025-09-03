import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones(); // Initialize timezone
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledTime}) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your channel id', // Elige un ID de canal
            'your channel name', // Elige un nombre de canal
            channelDescription: 'your channel description', // Descripción del canal
            importance: Importance.max, // O la importancia que necesites
            priority: Priority.high, // O la prioridad que necesites
            ticker: 'ticker',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("Alarma exacta programada para: $scheduledTime con ID: $id");
    } catch (e) {
      print("Error al programar la notificación exacta: $e");
    }
  }

  Future<void> scheduleDoseNotifications(Dose dose) async {
    final now = DateTime.now();
    if (dose.time.isBefore(now)) {
      // Don't schedule notifications for past doses
      return;
    }

    // Initial notification
    await scheduleNotification(
      id: dose.id.hashCode,
      title: 'Hora de tomar la medicación',
      body: 'Es hora de tomar ${dose.medicationName}',
      scheduledTime: dose.time,
    );

    // Reminders
    final reminderTimes = [
      dose.time.add(const Duration(hours: 1)),
      dose.time.add(const Duration(hours: 2)),
      dose.time.add(const Duration(hours: 3)),
    ];

    for (int i = 0; i < reminderTimes.length; i++) {
      final reminderTime = reminderTimes[i];
      if (reminderTime.isAfter(now)) {
        await scheduleNotification(
          id: dose.id.hashCode + i + 1,
          title: 'Recordatorio de medicación',
          body: 'No te olvides de tomar ${dose.medicationName}',
          scheduledTime: reminderTime,
        );
      }
    }

    // Midnight reminder
    final midnightOfNextDay = DateTime(dose.time.year, dose.time.month, dose.time.day + 1);
    if (midnightOfNextDay.isAfter(now)) {
      await scheduleNotification(
        id: dose.id.hashCode + 4, // Use a unique ID for midnight reminder
        title: 'Recordatorio final de medicación',
        body: 'Último recordatorio para ${dose.medicationName}',
        scheduledTime: midnightOfNextDay,
      );
    }
  }

  Future<void> cancelDoseNotifications(String doseId) async {
    // Cancel initial notification and 4 reminders (3 hourly + 1 midnight)
    for (int i = 0; i < 5; i++) {
      await flutterLocalNotificationsPlugin.cancel(doseId.hashCode + i);
    }
    print("Notificaciones canceladas para la dosis con ID base: ${doseId.hashCode}");
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}