import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/domain/entities/repetition_type.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/repositories/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  static Database? _database;
  static const String _medicationsTableName = 'medications';
  static const String _dosesTableName = 'doses';
  final NotificationService _notificationService = NotificationService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      await _notificationService.init();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'medications.db');
      return await openDatabase(
        path,
        version: 3, // Increased version number
        onCreate: (db, version) async {
          await _createMedicationsTable(db);
          await _createDosesTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < newVersion) {
            await db.execute('DROP TABLE IF EXISTS $_medicationsTableName');
            await db.execute('DROP TABLE IF EXISTS $_dosesTableName');
            await _createMedicationsTable(db);
            await _createDosesTable(db);
          }
        },
      );
    } catch (e) {
      print('Repository: Error al inicializar base de datos: $e');
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
        status TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_medicationsTableName);
      final medications = maps.map((map) => _mapToMedication(map)).toList();
      return medications;
    } catch (e) {
      print('Repository: Error en getAllMedications: $e');
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

    final doses = await db.query(_dosesTableName, where: 'medicationId = ?', whereArgs: [id]);
    for (final dose in doses) {
      await _notificationService.cancelNotification(dose['id'].hashCode);
    }

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
      repetitionType: RepetitionType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['repetitionType'] as String? ?? 'none'),
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
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        d.id,
        d.medicationId,
        m.name as medicationName,
        m.imagePath as medicationImagePath,
        d.time,
        d.status
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? OR d.status = ?
      ORDER BY d.time ASC
    ''', ['upcoming', 'expired']);
    return maps.map((map) => _mapToDose(map)).toList();
  }

  @override
  Future<List<Dose>> getPastDoses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        d.id,
        d.medicationId,
        m.name as medicationName,
        m.imagePath as medicationImagePath,
        d.time,
        d.status
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? OR d.status = ?
      ORDER BY d.time DESC
    ''', ['taken', 'notTaken']);
    return maps.map((map) => _mapToDose(map)).toList();
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
    await _notificationService.cancelNotification(dose.id.hashCode);
  }

  @override
  Future<void> deleteDose(String id) async {
    final db = await database;
    await db.delete(
      _dosesTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notificationService.cancelNotification(id.hashCode);
  }

  @override
  Future<void> generateDoses() async {
    final medications = await getAllMedications();
    final db = await database;
    final batch = db.batch();

    final now = DateTime.now();
    final threeMonthsFromNow = now.add(const Duration(days: 90));

    for (final medication in medications) {
      if (medication.repetitionType == RepetitionType.none) {
        for (final schedule in medication.schedules) {
          final doseTime = DateTime(
            medication.createdAt.year,
            medication.createdAt.month,
            medication.createdAt.day,
            schedule.hour,
            schedule.minute,
          );
          if (doseTime.isAfter(now.subtract(const Duration(days: 1)))) { // to include today's past doses
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
              _notificationService.scheduleNotification(
                id: dose.id.hashCode,
                title: 'Hora de tomar la medicación',
                body: 'Es hora de tomar ${medication.name}',
                scheduledTime: doseTime,
              );
            }
          }
        }
      } else {
        var currentDate = medication.createdAt;
        while (currentDate.isBefore(threeMonthsFromNow)) {
          if (medication.endDate != null && currentDate.isAfter(medication.endDate!)) {
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

            if (doseTime.isAfter(now.subtract(const Duration(days: 1)))) { // to include today's past doses
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
                _notificationService.scheduleNotification(
                  id: dose.id.hashCode,
                  title: 'Hora de tomar la medicación',
                  body: 'Es hora de tomar ${medication.name}',
                  scheduledTime: doseTime,
                );
              }
            }
          }

          if (medication.repetitionType == RepetitionType.daily) {
            currentDate = currentDate.add(Duration(days: medication.repetitionInterval ?? 1));
          } else if (medication.repetitionType == RepetitionType.weekly) {
            currentDate = currentDate.add(Duration(days: (medication.repetitionInterval ?? 1) * 7));
          } else if (medication.repetitionType == RepetitionType.monthly) {
            currentDate = DateTime(currentDate.year, currentDate.month + (medication.repetitionInterval ?? 1), currentDate.day);
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
        (e) => e.toString().split('.').last == (map['status'] as String? ?? 'upcoming'),
        orElse: () => DoseStatus.upcoming,
      ),
    );
  }
}