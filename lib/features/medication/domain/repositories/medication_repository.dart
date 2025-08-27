import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAllMedications();
  Future<Medication> saveMedication(Medication medication);
  Future<void> deleteMedication(String id);
  Future<Medication> updateMedication(Medication medication);

  Future<List<Dose>> getUpcomingDoses();
  Future<List<Dose>> getPastDoses();
  Future<void> updateDose(Dose dose);
  Future<void> deleteDose(String id);
  Future<void> generateDoses();
}
