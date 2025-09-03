import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
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

  const UpdateDoseStatusEvent(this.dose, this.status, {this.refreshPastDoses = false}); // Updated constructor

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

  const UpcomingDosesLoaded(this.doses);

  @override
  List<Object?> get props => [doses];
}

class PastDosesLoaded extends MedicationState {
  final List<Dose> doses;
  final Map<String, String> mostRecentDoseIds;

  const PastDosesLoaded(this.doses, this.mostRecentDoseIds);

  @override
  List<Object?> get props => [doses, mostRecentDoseIds];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
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

  MedicationBloc({
    required this.getMedications,
    required this.addMedication,
    required this.updateMedication,
    required this.deleteMedication,
    required this.getUpcomingDoses,
    required this.getPastDoses,
    required this.updateDoseStatus,
    required this.generateDoses,
  }) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedicationEvent>(_onAddMedication);
    on<UpdateMedicationEvent>(_onUpdateMedication);
    on<DeleteMedicationEvent>(_onDeleteMedication);
    on<LoadUpcomingDoses>(_onLoadUpcomingDoses);
    on<LoadPastDoses>(_onLoadPastDoses);
    on<UpdateDoseStatusEvent>(_onUpdateDoseStatus);
    on<GenerateDosesEvent>(_onGenerateDoses);
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
      emit(UpcomingDosesLoaded(doses));
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
      emit(PastDosesLoaded(result.doses, result.mostRecentDoseIds));
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
}