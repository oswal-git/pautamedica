import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class GetUpcomingDoses {
  final MedicationRepository repository;

  GetUpcomingDoses(this.repository);

  Future<List<Dose>> call() {
    return repository.getUpcomingDoses();
  }
}
