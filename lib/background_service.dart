import 'package:pautamedica/features/medication/data/notification_service.dart';
import 'package:pautamedica/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';

class BackgroundService {
  final MedicationRepositoryImpl _medicationRepository = MedicationRepositoryImpl();
  final NotificationService _notificationService = NotificationService();

  Future<void> executeTask() async {
    print("BackgroundService: executeTask started");
    await _notificationService.init();
    final upcomingDoses = await _medicationRepository.getUpcomingDoses();

    print("BackgroundService: Found ${upcomingDoses.length} upcoming doses.");

    for (final dose in upcomingDoses) {
      print("BackgroundService: Processing dose: ${dose.medicationName} at ${dose.time}, status: ${dose.status}, notificationSentCount: ${dose.notificationSentCount}");
      if (dose.status == DoseStatus.expired && dose.notificationSentCount < 4) {
        print("BackgroundService: Sending notification for expired dose: ${dose.medicationName}");
        await _notificationService.showNotification(
          dose: dose,
          title: 'Toma Vencida',
          body: 'No te olvides de tomar tu ${dose.medicationName}',
        );
        final updatedDose = dose.copyWith(notificationSentCount: dose.notificationSentCount + 1);
        await _medicationRepository.updateDose(updatedDose);
        print("BackgroundService: Notification sent and dose updated for ${dose.medicationName}. New count: ${updatedDose.notificationSentCount}");
      } else if (dose.status == DoseStatus.expired && dose.notificationSentCount >= 4) {
        print("BackgroundService: Max notifications sent for ${dose.medicationName}. Skipping.");
      }
    }
    print("BackgroundService: executeTask finished");
  }
}