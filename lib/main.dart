import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/app/app.dart';
import 'package:pautamedica/app/bloc_observer.dart';
import 'package:pautamedica/background_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background task started: $task");
    final backgroundService = BackgroundService();
    await backgroundService.executeTask();
    print("Background task finished: $task");
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
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
  runApp(const App());
}
