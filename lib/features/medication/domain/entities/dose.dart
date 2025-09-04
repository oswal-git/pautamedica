import 'package:equatable/equatable.dart';
import 'dose_status.dart';

class Dose extends Equatable {
  final String id;
  final String medicationId;
  final String medicationName;
  final String medicationImagePath;
  final DateTime time;
  final DoseStatus status;
  final int notificationSentCount;

  const Dose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.medicationImagePath,
    required this.time,
    required this.status,
    this.notificationSentCount = 0,
  });

  Dose copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? medicationImagePath,
    DateTime? time,
    DoseStatus? status,
    int? notificationSentCount,
  }) {
    return Dose(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      medicationImagePath: medicationImagePath ?? this.medicationImagePath,
      time: time ?? this.time,
      status: status ?? this.status,
      notificationSentCount: notificationSentCount ?? this.notificationSentCount,
    );
  }

  @override
  List<Object?> get props => [id, medicationId, medicationName, medicationImagePath, time, status, notificationSentCount];
}
