import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class DeletePastDosesOlderThan {
  final MedicationRepository repository;

  DeletePastDosesOlderThan(this.repository);

  Future<void> call(DateTime cutoff) {
    return repository.deletePastDosesOlderThan(cutoff);
  }
}
