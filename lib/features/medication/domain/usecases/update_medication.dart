import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class UpdateMedication {
  final MedicationRepository repository;

  UpdateMedication(this.repository);

  Future<Medication> call(Medication medication) {
    return repository.updateMedication(medication);
  }
}
