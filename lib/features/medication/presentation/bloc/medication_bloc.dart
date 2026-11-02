import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/repetition_type.dart';
import 'package:pautamedica/features/medication/domain/usecases/export_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/import_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/generate_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_past_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_upcoming_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/regenerate_doses_for_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/reorder_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_dose_status.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_dose.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_past_doses_older_than.dart';
import 'package:pautamedica/features/medication/domain/usecases/mark_past_doses_as_not_taken.dart';

import 'medication_event.dart';
import 'medication_state.dart';

final _logger = Logger();

// BLoC
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final GetMedications getMedications;
  final AddMedication addMedication;
  final AddDose addDose;
  final ReorderMedications reorderMedications;
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
  final MarkPastDosesAsNotTaken markPastDosesAsNotTaken;

  MedicationBloc({
    required this.getMedications,
    required this.addMedication,
    required this.addDose,
    required this.reorderMedications,
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
    required this.markPastDosesAsNotTaken,
  }) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedicationEvent>(_onAddMedication);
    on<RecordMedicationDoseEvent>(_onRecordMedicationDose);
    on<UpdateMedicationEvent>(_onUpdateMedication);
    on<ReorderMedicationsEvent>(_onReorderMedications);
    on<DeleteMedicationEvent>(_onDeleteMedication);
    on<LoadUpcomingDoses>(_onLoadUpcomingDoses);
    on<LoadPastDoses>(_onLoadPastDoses);
    on<UpdateDoseStatusEvent>(_onUpdateDoseStatus);
    on<GenerateDosesEvent>(_onGenerateDoses);
    on<ExportMedicationsEvent>(_onExportMedications);
    on<ImportMedicationsEvent>(_onImportMedications);
    on<DeleteDoseEvent>(_onDeleteDose);
    on<CleanPastDosesEvent>(_onCleanPastDoses);
    on<MarkPastDosesAsNotTakenEvent>(_onMarkPastDosesAsNotTaken);
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

  Future<void> _onRecordMedicationDose(
    RecordMedicationDoseEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final now = DateTime.now();
      await addDose(Dose(
        id: '${event.medication.id}_manual_${now.microsecondsSinceEpoch}',
        medicationId: event.medication.id,
        medicationName: event.medication.name,
        medicationImagePaths: event.medication.imagePaths,
        time: now,
        status: DoseStatus.taken,
        markedAt: now,
      ));
      add(LoadPastDoses());
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

  Future<void> _onReorderMedications(
    ReorderMedicationsEvent event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoaded(event.medications));
    try {
      await reorderMedications(
        event.medications.map((medication) => medication.id).toList(),
      );
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
      final medications = await getMedications();
      final medicationsMap = {for (var med in medications) med.id: med};
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
      final medications = await getMedications();
      final medicationsMap = {for (var med in medications) med.id: med};
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
      if (event.status == DoseStatus.upcoming) {
        final medications = await getMedications();
        if (medications.any((medication) =>
            medication.id == event.dose.medicationId &&
            medication.repetitionType == RepetitionType.asNeeded)) {
          return;
        }
      }
      final updatedDose =
          event.dose.copyWith(status: event.status, markedAt: DateTime.now());
      await updateDoseStatus(updatedDose);
      if (event.refreshPastDoses) {
        add(LoadPastDoses());
      } else {
        add(LoadUpcomingDoses());
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
      _logger.e("Error generating doses: ${e.toString()}");
      // No emitimos MedicationError para no bloquear la UI con un error de mantenimiento
    }
  }

  Future<void> _onExportMedications(
    ExportMedicationsEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final result = await exportMedications();
      if (result != null) {
        final filePath = result['filePath'];
        final medicationsCount = result['medicationsCount'] as int;
        final takenDosesCount = result['takenDosesCount'] as int;
        final notTakenDosesCount = result['notTakenDosesCount'] as int;
        final expiredDosesCount = result['expiredDosesCount'] as int;
        final totalDosesExported = result['totalDosesExported'] as int;

        emit(MedicationExportSuccess(
          'Datos exportados a:\n$filePath\n'
          'Medicamentos: $medicationsCount\n'
          'Dosis tomadas: $takenDosesCount\n'
          'Dosis desistidas: $notTakenDosesCount\n'
          'Dosis pasadas: $expiredDosesCount\n'
          'Total de dosis exportadas (no próximas): $totalDosesExported',
          medicationsCount: medicationsCount,
          takenDosesCount: takenDosesCount,
          notTakenDosesCount: notTakenDosesCount,
          expiredDosesCount: expiredDosesCount,
          totalDosesExported: totalDosesExported,
        ));
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
    emit(MedicationImportLoading());
    try {
      final result = await importMedications();
      if (result != null) {
        final medicationsCount = result['medicationsCount'] as int;
        final takenDosesCount = result['takenDosesCount'] as int;
        final notTakenDosesCount = result['notTakenDosesCount'] as int;
        final expiredDosesCount = result['expiredDosesCount'] as int;
        final totalDosesImported = result['totalDosesImported'] as int;

        emit(MedicationImportSuccess(
          medicationsCount: medicationsCount,
          takenDosesCount: takenDosesCount,
          notTakenDosesCount: notTakenDosesCount,
          expiredDosesCount: expiredDosesCount,
          totalDosesImported: totalDosesImported,
        ));
        add(LoadMedications()); // Reload medications to update UI
      } else {
        emit(const MedicationError('Importación cancelada por el usuario.'));
      }
    } catch (e) {
      _logger.e("Error al importar: ${e.toString()}");
      emit(MedicationError('Error al importar: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDose(
    DeleteDoseEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await deleteDose(event.id);
      add(LoadPastDoses());
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
      add(LoadPastDoses());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onMarkPastDosesAsNotTaken(
    MarkPastDosesAsNotTakenEvent event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await markPastDosesAsNotTaken(yesterday);
      add(GenerateDosesEvent());
      add(LoadMedications());
      emit(const PastDosesMarkedSuccess());
    } catch (e) {
      emit(MedicationError('Error al marcar dosis pasadas: ${e.toString()}'));
    }
  }
}
