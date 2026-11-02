import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class AddDose {
  final MedicationRepository repository;

  AddDose(this.repository);

  Future<void> call(Dose dose) => repository.addDose(dose);
}
