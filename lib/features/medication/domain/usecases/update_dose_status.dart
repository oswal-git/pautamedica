import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart'; // New import
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class UpdateDoseStatus {
  final MedicationRepository repository;

  UpdateDoseStatus(this.repository);

  Future<void> call(Dose dose) {
    // If the dose is being marked as taken, set the markedAt timestamp
    final updatedDose = dose.status == DoseStatus.taken
        ? dose.copyWith(markedAt: DateTime.now())
        : dose;
    return repository.updateDose(updatedDose);
  }
}
