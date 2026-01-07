import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class DeleteDose {
  final MedicationRepository repository;

  DeleteDose(this.repository);

  Future<void> call(String doseId) {
    return repository.deleteDose(doseId);
  }
}
