import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class GetPastDoses {
  final MedicationRepository repository;

  GetPastDoses(this.repository);

  Future<List<Dose>> call() {
    return repository.getPastDoses();
  }
}
