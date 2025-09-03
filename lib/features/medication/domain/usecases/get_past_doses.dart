import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';
import 'package:pautamedica/features/medication/domain/usecases/past_doses_result.dart';

class GetPastDoses {
  final MedicationRepository repository;

  GetPastDoses(this.repository);

  Future<PastDosesResult> call() {
    return repository.getPastDoses();
  }
}