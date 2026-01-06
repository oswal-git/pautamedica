import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/past_doses_result.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAllMedications();
  Future<Medication> saveMedication(Medication medication);
  Future<void> deleteMedication(String id);
  Future<Medication> updateMedication(Medication medication);

  Future<List<Dose>> getUpcomingDoses();
  Future<PastDosesResult> getPastDoses(); // Changed return type
  Future<void> updateDose(Dose dose);
  Future<void> deleteDose(String id);
  Future<void> generateDoses();

  Future<String?> exportMedications();
  Future<void> importMedications();
}
