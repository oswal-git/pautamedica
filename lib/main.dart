import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/app/app.dart';
import 'package:pautamedica/app/bloc_observer.dart';
import 'package:pautamedica/background_service.dart';
import 'package:pautamedica/features/medication/domain/usecases/export_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/import_medications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';

// Import MedicationBloc and its dependencies
import 'package:pautamedica/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:pautamedica/features/medication/domain/usecases/usecase_domain.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';

final _logger = Logger();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    _logger.i("Background task started: $task");
    final backgroundService = BackgroundService(
      medicationRepository: MedicationRepositoryImpl(),
      notificationService: NotificationService(),
    );
    await backgroundService.executeTask();
    _logger.i("Background task finished: $task");
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      create: (context) {
        final medicationRepository = MedicationRepositoryImpl();
        return MedicationBloc(
          getMedications: GetMedications(medicationRepository),
          addMedication: AddMedication(medicationRepository),
          updateMedication: UpdateMedication(medicationRepository),
          deleteMedication: DeleteMedication(medicationRepository),
          getUpcomingDoses: GetUpcomingDoses(medicationRepository),
          getPastDoses: GetPastDoses(medicationRepository),
          updateDoseStatus: UpdateDoseStatus(medicationRepository),
          generateDoses: GenerateDoses(medicationRepository),
          exportMedications: ExportMedications(medicationRepository),
          importMedications: ImportMedications(medicationRepository),
        )..add(GenerateDosesEvent());
      },
      child: const App(),
    ),
  );
}
