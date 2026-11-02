import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class ExportMedications {
  final MedicationRepository repository;

  ExportMedications(this.repository);
  Future<Map<String, dynamic>?> call() => repository.exportMedications();
}
