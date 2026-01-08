import 'package:equatable/equatable.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';

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

class CleanPastDosesEvent extends MedicationEvent {
  final DateTime cutoff;

  const CleanPastDosesEvent(this.cutoff);

  @override
  List<Object?> get props => [cutoff];
}
