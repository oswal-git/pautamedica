import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class RegenerateDosesForMedication {
  final MedicationRepository repository;

  RegenerateDosesForMedication(this.repository);

  Future<void> call(String medicationId) {
    return repository.regenerateDosesForMedication(medicationId);
  }
}
