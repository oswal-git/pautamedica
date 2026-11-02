import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class ImportMedications {
  final MedicationRepository repository;

  ImportMedications(this.repository);
  Future<Map<String, dynamic>?> call() => repository.importMedications();
}
