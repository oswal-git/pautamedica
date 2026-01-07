import 'package:get_it/get_it.dart';
import 'package:pautamedica/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_dose.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/export_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/generate_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_past_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_upcoming_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/import_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/regenerate_doses_for_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_dose_status.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_medication.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Repository
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(),
  );

  // BLoC
  sl.registerFactory(
    () => MedicationBloc(
      getMedications: sl(),
      addMedication: sl(),
      updateMedication: sl(),
      deleteMedication: sl(),
      getUpcomingDoses: sl(),
      getPastDoses: sl(),
      updateDoseStatus: sl(),
      generateDoses: sl(),
      regenerateDosesForMedication: sl(),
      exportMedications: sl(),
      importMedications: sl(),
      deleteDose: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMedications(sl()));
  sl.registerLazySingleton(() => AddMedication(sl()));
  sl.registerLazySingleton(() => UpdateMedication(sl()));
  sl.registerLazySingleton(() => DeleteMedication(sl()));
  sl.registerLazySingleton(() => GetUpcomingDoses(sl()));
  sl.registerLazySingleton(() => GetPastDoses(sl()));
  sl.registerLazySingleton(() => UpdateDoseStatus(sl()));
  sl.registerLazySingleton(() => GenerateDoses(sl()));
  sl.registerLazySingleton(() => RegenerateDosesForMedication(sl()));
  sl.registerLazySingleton(() => ExportMedications(sl()));
  sl.registerLazySingleton(() => ImportMedications(sl()));
  sl.registerLazySingleton(() => DeleteDose(sl()));
}
