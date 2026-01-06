import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> readJsonFromFile(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final List<dynamic> jsonData = jsonDecode(content);
    return jsonData.cast<Map<String, dynamic>>();
  }

  Future<String?> saveJsonToFile(String jsonString) async {
    final directory = await getExternalStorageDirectory();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: directory?.path,
    );

    if (selectedDirectory != null) {
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'pautamedica_backup_$timestamp.json';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      return filePath;
    }

    return null;
  }
}
