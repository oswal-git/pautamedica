import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/export_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/import_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/generate_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_past_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_upcoming_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/regenerate_doses_for_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_dose_status.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_dose.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_past_doses_older_than.dart';

import 'medication_event.dart';
import 'medication_state.dart';

// BLoC
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final GetMedications getMedications;
  final AddMedication addMedication;
  final UpdateMedication updateMedication;
  final DeleteMedication deleteMedication;
  final GetUpcomingDoses getUpcomingDoses;
  final GetPastDoses getPastDoses;
  final UpdateDoseStatus updateDoseStatus;
  final GenerateDoses generateDoses;
  final RegenerateDosesForMedication regenerateDosesForMedication;
  final ExportMedications exportMedications;
  final ImportMedications importMedications;
  final DeleteDose deleteDose;
  final DeletePastDosesOlderThan deletePastDosesOlderThan;

  MedicationBloc({
    required this.getMedications,
    required this.addMedication,
    required this.updateMedication,
    required this.deleteMedication,
    required this.getUpcomingDoses,
    required this.getPastDoses,
    required this.updateDoseStatus,
    required this.generateDoses,
    required this.regenerateDosesForMedication,
    required this.exportMedications,
    required this.importMedications,
    required this.deleteDose,
    required this.deletePastDosesOlderThan,
  }) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedicationEvent>(_onAddMedication);
    on<UpdateMedicationEvent>(_onUpdateMedication);
    on<DeleteMedicationEvent>(_onDeleteMedication);
    on<LoadUpcomingDoses>(_onLoadUpcomingDoses);
    on<LoadPastDoses>(_onLoadPastDoses);
    on<UpdateDoseStatusEvent>(_onUpdateDoseStatus);
    on<GenerateDosesEvent>(_onGenerateDoses);
    on<ExportMedicationsEvent>(_onExportMedications);
    on<ImportMedicationsEvent>(_onImportMedications);
    on<DeleteDoseEvent>(_onDeleteDose);
    on<CleanPastDosesEvent>(_onCleanPastDoses);
  }

  Future<void> _onLoadMedications(
    LoadMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final medications = await getMedications();
      emit(MedicationLoaded(medications));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onAddMedication(
    AddMedicationEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await addMedication(event.medication);
      add(GenerateDosesEvent());
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onUpdateMedication(
    UpdateMedicationEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await updateMedication(event.medication);
      await regenerateDosesForMedication(event.medication.id);
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedicationEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await deleteMedication(event.id);
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onLoadUpcomingDoses(
    LoadUpcomingDoses event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final doses = await getUpcomingDoses();
      final medications = await getMedications(); // Fetch all medications
      final medicationsMap = {
        for (var med in medications) med.id: med
      }; // Create a map
      emit(UpcomingDosesLoaded(doses, medicationsMap));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onLoadPastDoses(
    LoadPastDoses event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final result = await getPastDoses();
      final medications = await getMedications(); // Fetch all medications
      final medicationsMap = {
        for (var med in medications) med.id: med
      }; // Create a map
      emit(PastDosesLoaded(
          result.doses, result.mostRecentDoseIds, medicationsMap));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onUpdateDoseStatus(
    UpdateDoseStatusEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final updatedDose =
          event.dose.copyWith(status: event.status, markedAt: DateTime.now());
      await updateDoseStatus(updatedDose);
      if (event.refreshPastDoses) {
        add(LoadPastDoses()); // Refresh past doses list
      } else {
        add(LoadUpcomingDoses()); // Refresh upcoming doses list
      }
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onGenerateDoses(
    GenerateDosesEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await generateDoses();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onExportMedications(
    ExportMedicationsEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final filePath = await exportMedications();
      if (filePath != null) {
        emit(MedicationExportSuccess('Datos exportados a:\n$filePath'));
      } else {
        emit(const MedicationError('Exportación cancelada por el usuario.'));
      }
    } catch (e) {
      emit(MedicationError('Error al exportar: ${e.toString()}'));
    }
  }

  Future<void> _onImportMedications(
    ImportMedicationsEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await importMedications();
      emit(const MedicationImportSuccess());
      add(LoadMedications()); // Recargar los medicamentos para mostrar los datos importados.
    } catch (e) {
      emit(MedicationError('Error al importar: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDose(
    DeleteDoseEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await deleteDose(event.id);
      add(LoadPastDoses()); // Refresh past doses list
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onCleanPastDoses(
    CleanPastDosesEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await deletePastDosesOlderThan(event.cutoff);
      add(LoadPastDoses()); // Refresh past doses list
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
}
