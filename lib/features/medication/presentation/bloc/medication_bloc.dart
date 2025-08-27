import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

// Events
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedications extends MedicationEvent {}

class AddMedication extends MedicationEvent {
  final Medication medication;

  const AddMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class UpdateMedication extends MedicationEvent {
  final Medication medication;

  const UpdateMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

class DeleteMedication extends MedicationEvent {
  final String id;

  const DeleteMedication(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadUpcomingDoses extends MedicationEvent {}

class LoadPastDoses extends MedicationEvent {}

class UpdateDoseStatus extends MedicationEvent {
  final Dose dose;
  final DoseStatus status;

  const UpdateDoseStatus(this.dose, this.status);

  @override
  List<Object?> get props => [dose, status];
}

class DeleteDose extends MedicationEvent {
  final String id;

  const DeleteDose(this.id);

  @override
  List<Object?> get props => [id];
}

class GenerateDoses extends MedicationEvent {}

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

  const PastDosesLoaded(this.doses);

  @override
  List<Object?> get props => [doses];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _medicationRepository;

  MedicationBloc(this._medicationRepository) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<UpdateMedication>(_onUpdateMedication);
    on<DeleteMedication>(_onDeleteMedication);
    on<LoadUpcomingDoses>(_onLoadUpcomingDoses);
    on<LoadPastDoses>(_onLoadPastDoses);
    on<UpdateDoseStatus>(_onUpdateDoseStatus);
    on<DeleteDose>(_onDeleteDose);
    on<GenerateDoses>(_onGenerateDoses);
  }

  Future<void> _onLoadMedications(
    LoadMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    try {
      final medications = await _medicationRepository.getAllMedications();
      emit(MedicationLoaded(medications));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onAddMedication(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.saveMedication(event.medication);
      add(GenerateDoses());
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onUpdateMedication(
    UpdateMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.updateMedication(event.medication);
      add(GenerateDoses());
      add(LoadMedications());
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.deleteMedication(event.id);
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
      final doses = await _medicationRepository.getUpcomingDoses();
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
      final doses = await _medicationRepository.getPastDoses();
      emit(PastDosesLoaded(doses));
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onUpdateDoseStatus(
    UpdateDoseStatus event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      final updatedDose = event.dose.copyWith(status: event.status);
      await _medicationRepository.updateDose(updatedDose);
      add(LoadUpcomingDoses()); // Refresh the list
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onDeleteDose(
    DeleteDose event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.deleteDose(event.id);
      add(LoadPastDoses()); // Refresh the list
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }

  Future<void> _onGenerateDoses(
    GenerateDoses event,
    Emitter<MedicationState> emit,
  ) async {
    try {
      await _medicationRepository.generateDoses();
    } catch (e) {
      emit(MedicationError(e.toString()));
    }
  }
}