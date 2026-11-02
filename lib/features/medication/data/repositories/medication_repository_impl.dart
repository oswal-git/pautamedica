import 'dart:io';
import 'dart:convert'; // Added for jsonEncode/jsonDecode
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:pautamedica/features/medication/data/file_service.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';
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
  final _fileService = FileService();

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
        version: 8,
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
          if (oldVersion < 6) {
            // New migration for markedAt
            await db.execute(
                'ALTER TABLE $_dosesTableName ADD COLUMN markedAt TEXT');
            // Migrate existing past doses to have markedAt = time
            await db.rawUpdate(
                "UPDATE $_dosesTableName SET markedAt = time WHERE status IN ('taken', 'notTaken') AND markedAt IS NULL");
          }
          if (oldVersion < 7) {
            // New migration for description
            await db.execute(
                'ALTER TABLE $_medicationsTableName ADD COLUMN description TEXT NOT NULL DEFAULT ""');
          }
          if (oldVersion < 8) {
            await db.execute(
                'ALTER TABLE $_medicationsTableName ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0');
            await db.rawUpdate(
                'UPDATE $_medicationsTableName SET sortOrder = rowid');
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
        description TEXT NOT NULL DEFAULT '',
        posology TEXT NOT NULL,
        imagePaths TEXT NOT NULL, -- Changed to TEXT for JSON string
        schedules TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        firstDoseDate TEXT,
        repetitionType TEXT NOT NULL,
        repetitionInterval INTEGER,
        indefinite INTEGER NOT NULL,
        endDate TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0
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
        markedAt TEXT
      )
    ''');
  }

  @override
  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _medicationsTableName,
        orderBy: 'sortOrder ASC, rowid ASC',
      );

      final List<Medication> medications = [];
      for (final map in maps) {
        medications.add(await _mapToMedicationAsync(map));
      }
      return medications;
    } catch (e) {
      _logger.i('Repository: Error en getAllMedications: $e');
      rethrow;
    }
  }

  @override
  Future<Medication> saveMedication(Medication medication) async {
    final db = await database;
    final maxOrder = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT MAX(sortOrder) FROM $_medicationsTableName',
        )) ??
        -1;
    final map = await _medicationToMap(
      medication.copyWith(sortOrder: maxOrder + 1),
    );
    await db.insert(
      _medicationsTableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return medication;
  }

  @override
  Future<void> deleteMedication(String id) async {
    final db = await database;
    // Query the medication to get its image paths before deleting
    final List<Map<String, dynamic>> medicationMaps = await db.query(
      _medicationsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (medicationMaps.isNotEmpty) {
      final imagePathsJson = medicationMaps.first['imagePaths'] as String;
      final imageFileNames =
          (jsonDecode(imagePathsJson) as List).cast<String>();
      final docsDir = await getApplicationDocumentsDirectory();

      for (final fileName in imageFileNames) {
        final absolutePath = join(docsDir.path, fileName);
        final file = File(absolutePath);
        if (await file.exists()) {
          try {
            await file.delete();
            _logger.i('Repository: Deleted image file: $absolutePath');
          } catch (e) {
            _logger
                .e('Repository: Error deleting image file $absolutePath: $e');
          }
        }
      }
    } else {
      _logger.w(
          'Repository: Medication with ID $id not found for image deletion.');
    }

    // Delete the medication record from the database
    await db.delete(
      _medicationsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete associated doses
    await db.delete(
      _dosesTableName,
      where: 'medicationId = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Medication> updateMedication(Medication medication) async {
    final db = await database;
    final map =
        await _medicationToMap(medication); // Await the async map conversion
    await db.update(
      _medicationsTableName,
      map,
      where: 'id = ?',
      whereArgs: [medication.id],
    );
    return medication;
  }

  @override
  Future<void> reorderMedications(List<String> medicationIds) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var index = 0; index < medicationIds.length; index++) {
        batch.update(
          _medicationsTableName,
          {'sortOrder': index},
          where: 'id = ?',
          whereArgs: [medicationIds[index]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // Helper function to ensure an image file is copied to the app's persistent documents directory
  // if it's not already there, and returns its persistent absolute path.
  Future<String> _ensureImageIsPersistent(String imagePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = basename(imagePath);
    final persistentFilePath = join(docsDir.path, fileName);
    final originalFile = File(imagePath);

    // If the imagePath is already within the app's documents directory,
    // and the file exists, then it's already persistent.
    if (imagePath.startsWith(docsDir.path) && await originalFile.exists()) {
      return imagePath;
    }

    // If the original file exists (e.g., a temporary file from image_picker)
    // copy it to the persistent location.
    if (await originalFile.exists()) {
      try {
        await originalFile.copy(persistentFilePath);
        _logger.i(
            'Repository: Copied image from $imagePath to $persistentFilePath');
        return persistentFilePath;
      } catch (e) {
        _logger.e(
            'Repository: Error copying image $imagePath to $persistentFilePath: $e');
        // If copying fails, return the original path, which might be temporary or invalid.
        // This might lead to a broken image link.
        return imagePath;
      }
    } else {
      _logger.w(
          'Repository: Original image file not found at $imagePath. Cannot copy.');
      // If the original file doesn't exist, it's likely a temporary file that was cleaned up.
      // Return an empty string or null to indicate a broken path, or filter it out.
      // For now, returning an empty string to avoid issues with List<String> type.
      return ''; // Indicate that the image is not available.
    }
  }

  // Make _medicationToMap async to handle image persistence
  Future<Map<String, dynamic>> _medicationToMap(Medication medication) async {
    final List<String> persistentImagePaths = [];
    for (final path in medication.imagePaths) {
      final newPath = await _ensureImageIsPersistent(path);
      if (newPath.isNotEmpty) {
        // Only add if the path is valid (not empty string from error)
        persistentImagePaths.add(newPath);
      }
    }

    return {
      'id': medication.id,
      'name': medication.name,
      'description': medication.description,
      'posology': medication.posology,
      // Store only the basenames of the persistent paths
      'imagePaths': jsonEncode(
        persistentImagePaths.map((path) => basename(path)).toList(),
      ),
      'schedules':
          medication.schedules.map((dt) => dt.toIso8601String()).join(','),
      'createdAt': medication.createdAt.toIso8601String(),
      'firstDoseDate': medication.firstDoseDate?.toIso8601String(),
      'repetitionType': medication.repetitionType.toString().split('.').last,
      'repetitionInterval': medication.repetitionInterval,
      'indefinite': medication.indefinite ? 1 : 0,
      'endDate': medication.endDate?.toIso8601String(),
      'sortOrder': medication.sortOrder,
    };
  }

  // _mapToMedicationAsync already handles reconstructing absolute paths, no change needed here.
  // It is called by getAllMedications.
  Future<Medication> _mapToMedicationAsync(Map<String, dynamic> map) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final List<dynamic> relativePaths = jsonDecode(map['imagePaths'] as String);

    // Reconstruimos la ruta absoluta dinámica para el dispositivo actual
    final absolutePaths = relativePaths
        .map((fileName) => join(docsDir.path, fileName as String))
        .toList();

    final schedulesString = map['schedules'] as String;
    final schedules = schedulesString
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => DateTime.parse(s))
        .toList();

    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      posology: map['posology'] as String,
      imagePaths: absolutePaths,
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
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  // Make _mapToDose async to reconstruct absolute paths for doses
  Future<Dose> _mapToDoseAsync(Map<String, dynamic> map) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final List<dynamic> relativePaths =
        jsonDecode(map['medicationImagePaths'] as String);

    final absolutePaths = relativePaths
        .map((fileName) => join(docsDir.path, fileName))
        .toList()
        .cast<String>();

    return Dose(
      id: map['id'] as String,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      medicationImagePaths: absolutePaths, // Now absolute paths
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
        m.imagePaths as medicationImagePaths,
        d.time,
        d.status,
        d.notificationSentCount
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE (d.status = ? OR d.status = ?)
        AND m.repetitionType != ?
      ORDER BY d.time ASC
    ''', ['upcoming', 'expired', 'asNeeded']);

    final allDoses = await Future.wait(
        maps.map((map) => _mapToDoseAsync(map))); // Await all dose mappings
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
        m.imagePaths as medicationImagePaths, -- Changed
        d.time,
        d.status,
        d.notificationSentCount,
        d.markedAt -- Include markedAt in SELECT
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? OR d.status = ?
      ORDER BY d.time DESC
    ''', ['taken', 'notTaken']);

    final pastDoses = await Future.wait(
        maps.map((map) => _mapToDoseAsync(map))); // Await all dose mappings

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
  Future<void> addDose(Dose dose) async {
    final db = await database;
    await db.insert(_dosesTableName, _doseToMap(dose));
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
  Future<void> regenerateDosesForMedication(String medicationId) async {
    final db = await database;
    final notificationService = NotificationService();
    await notificationService.init();

    // Get all upcoming doses for this medication
    final List<Map<String, dynamic>> upcomingDosesMaps = await db.query(
      _dosesTableName,
      where: 'medicationId = ? AND status = ?',
      whereArgs: [medicationId, 'upcoming'],
    );

    // Cancel notifications for these doses
    for (final doseMap in upcomingDosesMaps) {
      final doseId = doseMap['id'] as String;
      await notificationService.cancelNotification(doseId);
    }

    // Delete all upcoming doses for this medication
    await db.delete(
      _dosesTableName,
      where: 'medicationId = ? AND status = ?',
      whereArgs: [medicationId, 'upcoming'],
    );

    final medications = await getAllMedications();
    final medication = medications.firstWhere((m) => m.id == medicationId);
    if (medication.repetitionType == RepetitionType.asNeeded) {
      await db.delete(
        _dosesTableName,
        where: 'medicationId = ? AND status = ?',
        whereArgs: [medicationId, 'expired'],
      );
      await rescheduleAllNotifications();
      return;
    }

    // Regenerate doses for this medication
    final batch = db.batch();

    final now = DateTime.now();

    // Calculamos un horizonte dinámico según el tipo de repetición
    DateTime targetDate;
    switch (medication.repetitionType) {
      case RepetitionType.daily:
        targetDate = now.add(const Duration(days: 30)); // 1 mes para diarios
        break;
      case RepetitionType.weekly:
        targetDate =
            now.add(const Duration(days: 90)); // ~3 meses para semanales
        break;
      case RepetitionType.monthly:
        // Generamos 3 ciclos (si es trimestral, serían 9 meses)
        final interval = medication.repetitionInterval ?? 1;
        targetDate = DateTime(now.year, now.month + (interval * 3), now.day);
        break;
      case RepetitionType.none:
      // ignore: unreachable_switch_default
      default:
        targetDate = now
            .add(const Duration(days: 7)); // Margen pequeño para tomas únicas
    }

    final startDate = medication.firstDoseDate != null &&
            medication.firstDoseDate!.isAfter(medication.createdAt)
        ? medication.firstDoseDate!
        : medication.createdAt;

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
              medicationImagePaths: medication.imagePaths,
              time: doseTime,
              status: DoseStatus.upcoming,
            );
            batch.insert(
              _dosesTableName,
              _doseToMap(dose),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
    } else {
      var currentDate = startDate;

      while (currentDate.isBefore(targetDate)) {
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
                medicationImagePaths: medication.imagePaths,
                time: doseTime,
                status: DoseStatus.upcoming,
              );
              batch.insert(
                _dosesTableName,
                _doseToMap(dose),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
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

    await batch.commit(noResult: true);
    await rescheduleAllNotifications();
  }

  @override
  Future<void> rescheduleAllNotifications() async {
    final notificationService = NotificationService();
    await notificationService.init();

    // Cancel all previously scheduled notifications
    await notificationService.cancelAllNotifications();

    final db = await database;
    final now = DateTime.now();

    // Fetch the next 50 upcoming doses with an INNER JOIN to get medication details
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        d.id,
        d.medicationId,
        m.name as medicationName,
        m.imagePaths as medicationImagePaths,
        d.time,
        d.status,
        d.notificationSentCount,
        d.markedAt
      FROM $_dosesTableName d
      INNER JOIN $_medicationsTableName m ON d.medicationId = m.id
      WHERE d.status = ? AND d.time > ?
        AND m.repetitionType != ?
      ORDER BY d.time ASC
      LIMIT 50
    ''', ['upcoming', now.toIso8601String(), 'asNeeded']);

    final upcomingDoses = await Future.wait(
        maps.map((map) => _mapToDoseAsync(map))); // Await here

    for (final dose in upcomingDoses) {
      await notificationService.scheduleNotification(
        dose: dose,
        title: 'Toma de Medicación',
        body: 'Es hora de tomar tu ${dose.medicationName}',
      );
    }

    _logger.i("Repository: Rescheduled ${upcomingDoses.length} notifications.");
  }

  @override
  Future<void> generateDoses() async {
    final medications = await getAllMedications();
    final db = await database;
    final batch = db.batch();

    final now = DateTime.now();

    for (final medication in medications) {
      if (medication.repetitionType == RepetitionType.asNeeded) {
        await db.delete(
          _dosesTableName,
          where: 'medicationId = ? AND (status = ? OR status = ?)',
          whereArgs: [medication.id, 'upcoming', 'expired'],
        );
        continue;
      }
      // Horizonte dinámico por medicamento
      DateTime targetDate;
      switch (medication.repetitionType) {
        case RepetitionType.daily:
          targetDate = now.add(const Duration(days: 30));
          break;
        case RepetitionType.weekly:
          targetDate = now.add(const Duration(days: 90));
          break;
        case RepetitionType.monthly:
          final interval = medication.repetitionInterval ?? 1;
          targetDate = DateTime(now.year, now.month + (interval * 3), now.day);
          break;
        case RepetitionType.none:
        // ignore: unreachable_switch_default
        default:
          targetDate = now.add(const Duration(days: 7));
      }

      final startDate = medication.firstDoseDate != null &&
              medication.firstDoseDate!.isAfter(medication.createdAt)
          ? medication.firstDoseDate!
          : medication.createdAt;

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
                medicationImagePaths: medication.imagePaths,
                time: doseTime,
                status: DoseStatus.upcoming,
              );
              batch.insert(
                _dosesTableName,
                _doseToMap(dose),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      } else {
        var currentDate = startDate;

        while (currentDate.isBefore(targetDate)) {
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
                  medicationImagePaths: medication.imagePaths, // Changed
                  time: doseTime,
                  status: DoseStatus.upcoming,
                );
                batch.insert(
                  _dosesTableName,
                  _doseToMap(dose),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
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

    // Mantenemos la limpieza de dosis muy antiguas (ej: más de 3 meses atrás)
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    await db.delete(
      _dosesTableName,
      where: 'time < ?',
      whereArgs: [threeMonthsAgo.toIso8601String()],
    );

    await rescheduleAllNotifications();
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

  @override
  Future<Map<String, dynamic>?> exportMedications() async {
    final db = await database;
    final medications =
        await getAllMedications(); // medications will have absolute paths
    final medicationsMaps = await db.query(_medicationsTableName);

    final takenDoses = await db
        .query(_dosesTableName, where: 'status = ?', whereArgs: ['taken']);
    final notTakenDoses = await db
        .query(_dosesTableName, where: 'status = ?', whereArgs: ['notTaken']);
    final expiredDoses = await db
        .query(_dosesTableName, where: 'status = ?', whereArgs: ['expired']);

    final allExportedDoses = await db.query(
      _dosesTableName,
      where: 'status != ?',
      whereArgs: ['upcoming'],
    );

    final dataToExport = {
      'medications': medicationsMaps,
      'doses': allExportedDoses,
      'stats': {
        'medicationsCount': medicationsMaps.length,
        'takenDosesCount': takenDoses.length,
        'notTakenDosesCount': notTakenDoses.length,
        'expiredDosesCount': expiredDoses.length,
        'totalDosesExported': allExportedDoses.length,
      }
    };

    final jsonString = jsonEncode(dataToExport);
    // No guardamos el JSON por separado, irá dentro del ZIP

    // Creamos el archivo ZIP
    final archive = Archive();

    // 1. Añadimos el JSON de datos
    final jsonBytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 2. Añadimos todas las imágenes físicas referenciadas
    for (final medication in medications) {
      for (final imagePath in medication.imagePaths) {
        // These are absolute paths
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(
              'images/${basename(imagePath)}', bytes.length, bytes));
        }
      }
    }

    // Codificamos y guardamos

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) return null;
    final filePath = await _fileService.saveJsonToFile(base64Encode(zipData));

    if (filePath != null) {
      return {
        'filePath': filePath,
        'medicationsCount': medicationsMaps.length,
        'takenDosesCount': takenDoses.length,
        'notTakenDosesCount': notTakenDoses.length,
        'expiredDosesCount': expiredDoses.length,
        'totalDosesExported': allExportedDoses.length,
      };
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> importMedications() async {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.cancelAllNotifications();

    final path = await _fileService.pickJsonFile();
    if (path != null) {
      // Leemos el archivo como string base64 y lo decodificamos a bytes binarios
      final base64String = await File(path).readAsString();
      final zipBytes = base64Decode(base64String);
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final jsonFile = archive.findFile('data.json');
      if (jsonFile == null) {
        _logger.e("Archivo de datos no encontrado en el backup");
        throw Exception("Archivo de datos no encontrado en el backup");
      }

      final content = utf8.decode(jsonFile.content);
      final Map<String, dynamic> jsonData = jsonDecode(content);

      final List<dynamic> medicationsToImport = jsonData['medications'] ?? [];
      final List<dynamic> dosesToImport = jsonData['doses'] ?? [];

      final db = await database;
      final docsDir = await getApplicationDocumentsDirectory();

      // Antes de borrar la base de datos, eliminamos físicamente las imágenes actuales
      // para evitar que se queden archivos huérfanos en el dispositivo.
      final currentMedications = await db.query(_medicationsTableName);
      for (final medMap in currentMedications) {
        try {
          final imagePathsJson = medMap['imagePaths'] as String?;
          if (imagePathsJson != null) {
            final imageFileNames =
                (jsonDecode(imagePathsJson) as List).cast<String>();
            for (final fileName in imageFileNames) {
              final file = File(
                  join(docsDir.path, fileName)); // Reconstruct absolute path
              if (await file.exists()) {
                await file.delete();
              }
            }
          }
        } catch (e) {
          _logger.e("Error al limpiar imagen previa a importación: $e");
        }
      }

      // 1. Extraemos las imágenes físicas del ZIP al almacenamiento local
      for (final file in archive) {
        if (file.name.startsWith('images/') && file.isFile) {
          final fileName = basename(file.name);
          final outFile = File(join(docsDir.path, fileName));
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // 2. Limpiamos las tablas con DELETE (seguro con el singleton de _database).
      //    No usamos DROP+CREATE: invalida el schema cacheado en la instancia
      //    singleton y provoca UNIQUE constraint en la segunda importacion.
      await db.delete(_dosesTableName);
      await db.delete(_medicationsTableName);

      _logger.i(
          'Import: Tablas limpias. Insertando ${medicationsToImport.length} medications y ${dosesToImport.length} doses');

      // 3. Insertamos los registros en un batch para mayor velocidad y atomicidad
      final batch = db.batch();
      for (final medication in medicationsToImport) {
        batch.insert(_medicationsTableName, medication as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final dose in dosesToImport) {
        batch.insert(_dosesTableName, dose as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      // After import, get the counts for the imported data
      final importedMedicationsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_medicationsTableName'));
      final importedDosesCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_dosesTableName'));
      final importedTakenDosesCount = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM $_dosesTableName WHERE status = 'taken'"));
      final importedNotTakenDosesCount = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM $_dosesTableName WHERE status = 'notTaken'"));
      final importedExpiredDosesCount = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM $_dosesTableName WHERE status = 'expired'"));

      await generateDoses();

      return {
        'medicationsCount': importedMedicationsCount,
        'takenDosesCount': importedTakenDosesCount,
        'notTakenDosesCount': importedNotTakenDosesCount,
        'expiredDosesCount': importedExpiredDosesCount,
        'totalDosesImported': importedDosesCount,
      };
    }
    return null;
  }

  @override
  Future<void> deletePastDosesOlderThan(DateTime cutoff) async {
    final db = await database;
    await db.delete(
      _dosesTableName,
      where: 'markedAt < ? AND (status = ? OR status = ?)',
      whereArgs: [cutoff.toIso8601String(), 'taken', 'notTaken'],
    );
  }

  @override
  Future<void> markPastDosesAsNotTaken(DateTime cutoff) async {
    final db = await database;
    final now = DateTime.now();
    await db.update(
      _dosesTableName,
      {
        'status': 'notTaken',
        'markedAt': now.toIso8601String(),
      },
      where:
          'time < ? AND (status = ? OR status = ? OR status = ? OR status = ? OR status = ? )',
      whereArgs: [
        cutoff.toIso8601String(),
        'expired',
        'upcoming',
        'taken',
        'notTaken',
      ],
    );
  }
}
