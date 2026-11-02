import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class MarkPastDosesAsNotTaken {
  final MedicationRepository repository;

  MarkPastDosesAsNotTaken(this.repository);

  Future<void> call(DateTime cutoff) =>
      repository.markPastDosesAsNotTaken(cutoff);
}
