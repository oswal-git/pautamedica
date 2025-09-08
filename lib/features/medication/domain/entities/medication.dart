import 'package:equatable/equatable.dart';

import 'repetition_type.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final String posology;
  final List<String> imagePaths;
  final List<DateTime> schedules;
  final DateTime createdAt;
  final DateTime? firstDoseDate; // New field

  // New fields for repetition
  final RepetitionType repetitionType;
  final int? repetitionInterval; // Nullable if repetitionType is none
  final bool indefinite;
  final DateTime? endDate; // Replaces repeatEndDate

  const Medication({
    required this.id,
    required this.name,
    required this.posology,
    required this.imagePaths,
    required this.schedules,
    required this.createdAt,
    this.firstDoseDate,
    this.repetitionType = RepetitionType.none,
    this.repetitionInterval,
    this.indefinite = false,
    this.endDate,
  });

    Medication copyWith({
    String? id,
    String? name,
    String? posology,
    List<String>? imagePaths,
    List<DateTime>? schedules,
    DateTime? createdAt,
    DateTime? firstDoseDate, // New field
    RepetitionType? repetitionType,
    int? repetitionInterval,
    bool? indefinite,
    DateTime? endDate,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      posology: posology ?? this.posology,
      imagePaths: imagePaths ?? this.imagePaths,
      schedules: schedules ?? this.schedules,
      createdAt: createdAt ?? this.createdAt,
      firstDoseDate: firstDoseDate ?? this.firstDoseDate,
      repetitionType: repetitionType ?? this.repetitionType,
      repetitionInterval: repetitionInterval ?? this.repetitionInterval,
      indefinite: indefinite ?? this.indefinite,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        posology,
        imagePaths,
        schedules,
        createdAt,
        firstDoseDate,
        repetitionType,
        repetitionInterval,
        indefinite,
        endDate,
      ];
}