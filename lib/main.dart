import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/app/app.dart';
import 'package:pautamedica/app/bloc_observer.dart';
import 'package:pautamedica/background_service.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_event.dart';
import 'package:pautamedica/core/di/injection_container.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';

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

  // Initialize dependency injection
  await init();

  Workmanager().initialize(
    callbackDispatcher,
  );
  Workmanager().registerOneOffTask(
    '2',
    'pautamedica_one_off_dose_check',
    initialDelay: Duration(seconds: 10),
  );
  Workmanager().registerPeriodicTask(
    '1',
    'pautamedica_dose_check',
    frequency: const Duration(hours: 1),
  );
  Bloc.observer = AppBlocObserver();
  runApp(
    BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(GenerateDosesEvent()),
      child: const App(),
    ),
  );
}
