import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class UpdateDoseStatus {
  final MedicationRepository repository;

  UpdateDoseStatus(this.repository);

  Future<void> call(Dose dose) {
    return repository.updateDose(dose);
  }
}
