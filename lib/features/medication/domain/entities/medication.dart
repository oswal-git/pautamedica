import 'package:equatable/equatable.dart';

import 'repetition_type.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final String description;
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
  final int sortOrder;

  const Medication({
    required this.id,
    required this.name,
    this.description = '',
    required this.posology,
    required this.imagePaths,
    required this.schedules,
    required this.createdAt,
    this.firstDoseDate,
    this.repetitionType = RepetitionType.none,
    this.repetitionInterval,
    this.indefinite = false,
    this.endDate,
    this.sortOrder = 0,
  });

    Medication copyWith({
    String? id,
    String? name,
    String? description,
    String? posology,
    List<String>? imagePaths,
    List<DateTime>? schedules,
    DateTime? createdAt,
    DateTime? firstDoseDate, // New field
    RepetitionType? repetitionType,
    int? repetitionInterval,
    bool? indefinite,
    DateTime? endDate,
    int? sortOrder,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      posology: posology ?? this.posology,
      imagePaths: imagePaths ?? this.imagePaths,
      schedules: schedules ?? this.schedules,
      createdAt: createdAt ?? this.createdAt,
      firstDoseDate: firstDoseDate ?? this.firstDoseDate,
      repetitionType: repetitionType ?? this.repetitionType,
      repetitionInterval: repetitionInterval ?? this.repetitionInterval,
      indefinite: indefinite ?? this.indefinite,
      endDate: endDate ?? this.endDate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        posology,
        imagePaths,
        schedules,
        createdAt,
        firstDoseDate,
        repetitionType,
        repetitionInterval,
        indefinite,
        endDate,
        sortOrder,
      ];
}
