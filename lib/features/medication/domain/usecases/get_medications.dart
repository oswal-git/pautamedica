import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class GetMedications {
  final MedicationRepository repository;

  GetMedications(this.repository);

  Future<List<Medication>> call() {
    return repository.getAllMedications();
  }
}
