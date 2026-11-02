import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class ReorderMedications {
  final MedicationRepository repository;

  ReorderMedications(this.repository);

  Future<void> call(List<String> medicationIds) {
    return repository.reorderMedications(medicationIds);
  }
}
