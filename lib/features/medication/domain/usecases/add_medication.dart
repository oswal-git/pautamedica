import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class AddMedication {
  final MedicationRepository repository;

  AddMedication(this.repository);

  Future<Medication> call(Medication medication) {
    return repository.saveMedication(medication);
  }
}
