import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/repetition_type.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';
import 'package:pautamedica/features/medication/domain/usecases/past_doses_result.dart';

final _logger = Logger();

class MedicationRepositoryImpl implements MedicationRepository {
  static Database? _database;
  static const String _medicationsTableName = 'medications';
  static const String _dosesTableName = 'doses';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'medications.db');
      return await openDatabase(
        path,
        version: 6, // Increment version
        onCreate: (db, version) async {
          await _createMedicationsTable(db);
          await _createDosesTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 4) {
            await db.execute(
                'ALTER TABLE $_medicationsTableName ADD COLUMN firstDoseDate TEXT');
            await db.rawUpdate(
                'UPDATE $_medicationsTableName SET firstDoseDate = createdAt WHERE firstDoseDate IS NULL');
          }
          if (oldVersion < 5) {
            await db.execute(
                'ALTER TABLE $_dosesTableName ADD COLUMN notificationSentCount INTEGER NOT NULL DEFAULT 0');
          }
          if (oldVersion < 6) { // New migration for markedAt
            await db.execute(
                'ALTER TABLE $_dosesTableName ADD COLUMN markedAt TEXT');
            // Migrate existing past doses to have markedAt = time
            await db.rawUpdate(
                "UPDATE $_dosesTableName SET markedAt = time WHERE status IN ('taken', 'notTaken') AND markedAt IS NULL");
          }
        },
      );
    } catch (e) {
      _logger.i('Repository: Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  Future<void> _createMedicationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_medicationsTableName(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        posology TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        schedules TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        firstDoseDate TEXT,
        repetitionType TEXT NOT NULL,
        repetitionInterval INTEGER,
        indefinite INTEGER NOT NULL,
        endDate TEXT
      )
    ''');
  }

  Future<void> _createDosesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_dosesTableName(
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL,
        notificationSentCount INTEGER NOT NULL DEFAULT 0,
        markedAt TEXT // New column
      )
    ''');
  }

  @override
  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps =
          await db.query(_medicationsTableName);
      final medications = maps.map((map) => _mapToMedication(map)).toList();
      return medications;
    } catch (e) {
      _logger.i('Repository: Error en getAllMedications: $e');
      rethrow;
    }
  }

  @override
  Future<Medication> saveMedication(Medication medication) async {
    final db = await database;
    await db.insert(
      _medicationsTableName,
      _medicationToMap(medication),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return medication;
  }

  @override
    Future<void> deleteMedication(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      _medicationsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final imagePath = result.first['imagePath'] as String;
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.delete(
      _medicationsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    await db.delete(
      _dosesTableName,
      where: 'medicationId = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Medication> updateMedication(Medication medication) async {
    final db = await database;
    await db.update(
      _medicationsTableName,
      _medicationToMap(medication),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
    return medication;
  }

  Map<String, dynamic> _medicationToMap(Medication medication) {
    return {
      'id': medication.id,
      'name': medication.name,
      'posology': medication.posology,
      'imagePath': medication.imagePath,
      'schedules':
          medication.schedules.map((dt) => dt.toIso8601String()).join(','),
      'createdAt': medication.createdAt.toIso8601String(),
      'firstDoseDate': medication.firstDoseDate?.toIso8601String(),
      'repetitionType': medication.repetitionType.toString().split('.').last,
      'repetitionInterval': medication.repetitionInterval,
      'indefinite': medication.indefinite ? 1 : 0,
      'endDate': medication.endDate?.toIso8601String(),
    };
  }

  Medication _mapToMedication(Map<String, dynamic> map) {
    final schedulesString = map['schedules'] as String;
    final schedules = schedulesString
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => DateTime.parse(s))
        .toList();

    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      posology: map['posology'] as String,
      imagePath: map['imagePath'] as String,
      schedules: schedules,
      createdAt: DateTime.parse(map['createdAt'] as String),
      firstDoseDate: map['firstDoseDate'] != null
          ? DateTime.parse(map['firstDoseDate'] as String)
          : null,
      repetitionType: RepetitionType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (map['repetitionType'] as String? ?? 'none'),
        orElse: () => RepetitionType.none,
      ),
      repetitionInterval: map['repetitionInterval'] as int?,
      indefinite: (map['indefinite'] as num? ?? 0) == 1,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
    );
  }

  @override
  Future<List<Dose>> getUpcomingDoses() async {
    final db = await database;

    // Update statuses of upcoming doses to expired if they are in the past
    final now = DateTime.now();
    await db.update(
      _dosesTableName,
      {'status': 'expired'},
      where: 'status = ? AND time < ?',
      whereArgs: ['upcoming', now.toIso8601String()],
    );

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        d.id,
        d.medicationId,
        m.name as medicationName,
        m.imagePath as medicationImagePath,
        d.time,
        d.status,
        d.notificationSentCount
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? OR d.status = ?
      ORDER BY d.time ASC
    ''', ['upcoming', 'expired']);

    final allDoses = maps.map((map) => _mapToDose(map)).toList();
    final Map<String, List<Dose>> dosesByMedication = {};

    for (final dose in allDoses) {
      if (!dosesByMedication.containsKey(dose.medicationId)) {
        dosesByMedication[dose.medicationId] = [];
      }
      dosesByMedication[dose.medicationId]!.add(dose);
    }

    final List<Dose> upcomingDoses = [];
    dosesByMedication.forEach((medicationId, doses) {
      if (doses.isNotEmpty) {
        final firstDose = doses.first;
        if (firstDose.status == DoseStatus.upcoming) {
          upcomingDoses.add(firstDose);
        } else if (firstDose.status == DoseStatus.expired) {
          upcomingDoses.add(firstDose);
          final nextUpcoming = doses.firstWhereOrNull(
            (d) => d.status == DoseStatus.upcoming,
          );
          if (nextUpcoming != null) {
            upcomingDoses.add(nextUpcoming);
          }
        }
      }
    });

    upcomingDoses.sort((a, b) => a.time.compareTo(b.time));

    return upcomingDoses;
  }

  @override
  Future<PastDosesResult> getPastDoses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        d.id,
        d.medicationId,
        m.name as medicationName,
        m.imagePath as medicationImagePath,
        d.time,
        d.status,
        d.notificationSentCount,
        d.markedAt -- Include markedAt in SELECT
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? OR d.status = ?
      ORDER BY d.time DESC
    ''', ['taken', 'notTaken']);

    final List<Dose> pastDoses = maps.map((map) => _mapToDose(map)).toList();

    final Map<String, String> mostRecentDoseIds = {};
    final Set<String> processedMedicationIds = {};

    for (final dose in pastDoses) {
      if (!processedMedicationIds.contains(dose.medicationId)) {
        mostRecentDoseIds[dose.medicationId] = dose.id;
        processedMedicationIds.add(dose.medicationId);
      }
    }

    return PastDosesResult(
        doses: pastDoses, mostRecentDoseIds: mostRecentDoseIds);
  }

  @override
  Future<void> updateDose(Dose dose) async {
    final db = await database;
    await db.update(
      _dosesTableName,
      _doseToMap(dose),
      where: 'id = ?',
      whereArgs: [dose.id],
    );
  }

  @override
  Future<void> deleteDose(String id) async {
    final db = await database;
    await db.delete(
      _dosesTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> generateDoses() async {
    final medications = await getAllMedications();
    final db = await database;
    final batch = db.batch();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeMonthsFromNow = now.add(const Duration(days: 90));

    for (final medication in medications) {
      final startDate = medication.firstDoseDate != null &&
              medication.firstDoseDate!.isAfter(medication.createdAt)
          ? medication.firstDoseDate!
          : medication.createdAt;

      if (medication.firstDoseDate != null &&
          medication.firstDoseDate!.isAfter(now)) {
        continue;
      }

      if (medication.repetitionType == RepetitionType.none) {
        for (final schedule in medication.schedules) {
          final doseTime = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            schedule.hour,
            schedule.minute,
          );
          if (doseTime.isAfter(now.subtract(const Duration(days: 1)))) {
            final existingDoses = await db.query(
              _dosesTableName,
              where: 'medicationId = ? AND time = ?',
              whereArgs: [medication.id, doseTime.toIso8601String()],
            );
            if (existingDoses.isEmpty) {
              final dose = Dose(
                id: '${medication.id}_${doseTime.toIso8601String()}',
                medicationId: medication.id,
                medicationName: medication.name,
                medicationImagePath: medication.imagePath,
                time: doseTime,
                status: DoseStatus.upcoming,
              );
              batch.insert(_dosesTableName, _doseToMap(dose));
            }
          }
        }
      } else {
        var currentDate = startDate;

        if (currentDate.isBefore(today)) {
          currentDate = today;
        }

        while (currentDate.isBefore(threeMonthsFromNow)) {
          if (medication.endDate != null &&
              currentDate.isAfter(medication.endDate!)) {
            break;
          }

          for (final schedule in medication.schedules) {
            final doseTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              schedule.hour,
              schedule.minute,
            );

            if (doseTime.isAfter(now.subtract(const Duration(days: 1)))) {
              final existingDoses = await db.query(
                _dosesTableName,
                where: 'medicationId = ? AND time = ?',
                whereArgs: [medication.id, doseTime.toIso8601String()],
              );
              if (existingDoses.isEmpty) {
                final dose = Dose(
                  id: '${medication.id}_${doseTime.toIso8601String()}',
                  medicationId: medication.id,
                  medicationName: medication.name,
                  medicationImagePath: medication.imagePath,
                  time: doseTime,
                  status: DoseStatus.upcoming,
                );
                batch.insert(_dosesTableName, _doseToMap(dose));
              }
            }
          }

          if (medication.repetitionType == RepetitionType.daily) {
            currentDate = currentDate
                .add(Duration(days: medication.repetitionInterval ?? 1));
          } else if (medication.repetitionType == RepetitionType.weekly) {
            currentDate = currentDate
                .add(Duration(days: (medication.repetitionInterval ?? 1) * 7));
          } else if (medication.repetitionType == RepetitionType.monthly) {
            currentDate = DateTime(
                currentDate.year,
                currentDate.month + (medication.repetitionInterval ?? 1),
                currentDate.day);
          }
        }
      }
    }

    await batch.commit(noResult: true);

    // Delete doses older than 3 months
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    await db.delete(
      _dosesTableName,
      where: 'time < ?',
      whereArgs: [threeMonthsAgo.toIso8601String()],
    );
  }

  Map<String, dynamic> _doseToMap(Dose dose) {
    return {
      'id': dose.id,
      'medicationId': dose.medicationId,
      'time': dose.time.toIso8601String(),
      'status': dose.status.toString().split('.').last,
      'notificationSentCount': dose.notificationSentCount,
      'markedAt': dose.markedAt?.toIso8601String(), // New field
    };
  }

  Dose _mapToDose(Map<String, dynamic> map) {
    return Dose(
      id: map['id'] as String,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      medicationImagePath: map['medicationImagePath'] as String,
      time: DateTime.parse(map['time'] as String),
      status: DoseStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (map['status'] as String? ?? 'upcoming'),
        orElse: () => DoseStatus.upcoming,
      ),
      notificationSentCount: map['notificationSentCount'] as int? ?? 0,
      markedAt: map['markedAt'] != null
          ? DateTime.parse(map['markedAt'] as String)
          : null, // New field
    );
  }
}
