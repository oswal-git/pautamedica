import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/app/app.dart';
import 'package:pautamedica/app/bloc_observer.dart';
import 'package:pautamedica/background_service.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/core/di/injection_container.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

final _logger = Logger();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _logger.i("Background task started: $task");
    // Initialize dependency injection for background tasks
    await init();
    final backgroundService = BackgroundService(
      medicationRepository: sl(),
      notificationService: NotificationService(),
    );
    await backgroundService.executeTask();
    _logger.i("Background task finished: $task");
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize dependency injection
    await init();

    // Request permissions for notifications and exact alarms
    await [
      Permission.notification,
      Permission.scheduleExactAlarm,
    ].request();
  } catch (e, stackTrace) {
    _logger.e("Initialization error", error: e, stackTrace: stackTrace);
  }

  Workmanager().initialize(
    callbackDispatcher,
  );
  Workmanager().registerPeriodicTask(
    '1',
    'pautamedica_dose_check',
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  Bloc.observer = AppBlocObserver();
  runApp(
    BlocProvider(
      create: (context) => sl<MedicationBloc>(),
      child: const App(),
    ),
  );
}
