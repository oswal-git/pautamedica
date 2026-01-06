import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class ImportMedications {
  final MedicationRepository repository;

  ImportMedications(this.repository);
  Future<void> call() => repository.importMedications();
}
