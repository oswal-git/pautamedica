import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class ExportMedications {
  final MedicationRepository repository;

  ExportMedications(this.repository);
  Future<String?> call() => repository.exportMedications();
}
