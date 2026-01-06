import 'package:logger/logger.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';

class BackgroundService {
  final _logger = Logger();
  final MedicationRepository _medicationRepository;
  final NotificationService _notificationService;

  BackgroundService({
    required MedicationRepository medicationRepository,
    required NotificationService notificationService,
  })  : _medicationRepository = medicationRepository,
        _notificationService = notificationService;

  Future<void> executeTask() async {
    _logger.i("BackgroundService: executeTask started");
    await _notificationService.init();
    final upcomingDoses = await _medicationRepository.getUpcomingDoses();

    _logger
        .i("BackgroundService: Found ${upcomingDoses.length} upcoming doses.");

    for (final dose in upcomingDoses) {
      _logger.i(
          "BackgroundService: Processing dose: ${dose.medicationName} at ${dose.time}, status: ${dose.status}, notificationSentCount: ${dose.notificationSentCount}");
      if (dose.status == DoseStatus.expired && dose.notificationSentCount < 4) {
        _logger.i(
            "BackgroundService: Sending notification for expired dose: ${dose.medicationName}");
        await _notificationService.showNotification(
          dose: dose,
          title: 'Toma Vencida',
          body: 'No te olvides de tomar tu ${dose.medicationName}',
        );
        final updatedDose = dose.copyWith(
            notificationSentCount: dose.notificationSentCount + 1);
        await _medicationRepository.updateDose(updatedDose);
        _logger.i(
            "BackgroundService: Notification sent and dose updated for ${dose.medicationName}. New count: ${updatedDose.notificationSentCount}");
      } else if (dose.status == DoseStatus.expired &&
          dose.notificationSentCount >= 4) {
        _logger.w(
            "BackgroundService: Max notifications sent for ${dose.medicationName}. Skipping.");
      }
    }
    _logger.i("BackgroundService: executeTask finished");
  }
}
