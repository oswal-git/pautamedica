import 'package:equatable/equatable.dart';
import 'dose_status.dart';

class Dose extends Equatable {
  final String id;
  final String medicationId;
  final String medicationName;
  final List<String> medicationImagePaths;
  final DateTime time;
  final DoseStatus status;
  final int notificationSentCount;
  final DateTime? markedAt; // New field

  const Dose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.medicationImagePaths,
    required this.time,
    required this.status,
    this.notificationSentCount = 0,
    this.markedAt, // New field
  });

  Dose copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    List<String>? medicationImagePaths,
    DateTime? time,
    DoseStatus? status,
    int? notificationSentCount,
    DateTime? markedAt, // New field
  }) {
    return Dose(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      medicationImagePaths: medicationImagePaths ?? this.medicationImagePaths,
      time: time ?? this.time,
      status: status ?? this.status,
      notificationSentCount: notificationSentCount ?? this.notificationSentCount,
      markedAt: markedAt ?? this.markedAt, // New field
    );
  }

  @override
  List<Object?> get props => [
            id,
            medicationId,
            medicationName,
            medicationImagePaths,
            time,
            status,
            notificationSentCount,
            markedAt, // New field
          ];
}
