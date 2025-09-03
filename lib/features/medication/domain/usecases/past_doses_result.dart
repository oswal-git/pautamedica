import 'package:pautamedica/features/medication/domain/entities/dose.dart';

class PastDosesResult {
  final List<Dose> doses;
  final Map<String, String> mostRecentDoseIds;

  PastDosesResult({required this.doses, required this.mostRecentDoseIds});
}