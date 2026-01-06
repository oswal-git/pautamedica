import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/export_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/import_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/generate_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_past_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_upcoming_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_dose_status.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_medication.dart';

// Events
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedications extends MedicationEvent {}

class AddMedicationEvent extends MedicationEvent {
  final Medication medication;

  const AddMedicationEvent(this.medication);

  @override
  List<Object?> get props => [medication];
}

class UpdateMedicationEvent extends MedicationEvent {
  final Medication medication;

  const UpdateMedicationEvent(this.medication);

  @override
  List<Object?> get props => [medication];
}

class DeleteMedicationEvent extends MedicationEvent {
  final String id;

  const DeleteMedicationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadUpcomingDoses extends MedicationEvent {}

class LoadPastDoses extends MedicationEvent {}

class UpdateDoseStatusEvent extends MedicationEvent {
  final Dose dose;
  final DoseStatus status;
  final bool refreshPastDoses; // New parameter

  const UpdateDoseStatusEvent(this.dose, this.status,
      {this.refreshPastDoses = false}); // Updated constructor

  @override
  List<Object?> get props => [dose, status, refreshPastDoses]; // Updated props
}

class DeleteDoseEvent extends MedicationEvent {
  final String id;

  const DeleteDoseEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class GenerateDosesEvent extends MedicationEvent {}

class ExportMedicationsEvent extends MedicationEvent {}

class ImportMedicationsEvent extends MedicationEvent {}

// States
abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<Medication> medications;

  const MedicationLoaded(this.medications);

  @override
  List<Object?> get props => [medications];
}

class UpcomingDosesLoaded extends MedicationState {
  final List<Dose> doses;
  final Map<String, Medication> medicationsMap;

  const UpcomingDosesLoaded(this.doses, this.medicationsMap);

  @override
  List<Object?> get props => [doses, medicationsMap];
}

class PastDosesLoaded extends MedicationState {
  final List<Dose> doses;
  final Map<String, String> mostRecentDoseIds;
  final Map<String, Medication> medicationsMap;

  const PastDosesLoaded(
      this.doses, this.mostRecentDoseIds, this.medicationsMap);

  @override
  List<Object?> get props => [doses, mostRecentDoseIds, medicationsMap];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicationExportSuccess extends MedicationState {
  final String message;
  const MedicationExportSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class MedicationImportSuccess extends MedicationState {
  const MedicationImportSuccess();
}

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
  final ExportMedications exportMedications;
  final ImportMedications importMedications;

  MedicationBloc({
    required this.getMedications,
    required this.addMedication,
    required this.updateMedication,
    required this.deleteMedication,
    required this.getUpcomingDoses,
    required this.getPastDoses,
    required this.updateDoseStatus,
    required this.generateDoses,
    required this.exportMedications,
    required this.importMedications,
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
      add(GenerateDosesEvent());
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
      final updatedDose = event.dose.copyWith(status: event.status);
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
}
