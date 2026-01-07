import 'package:equatable/equatable.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';

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
