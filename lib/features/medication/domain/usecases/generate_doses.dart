import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class GenerateDoses {
  final MedicationRepository repository;

  GenerateDoses(this.repository);

  Future<void> call() {
    return repository.generateDoses();
  }
}
