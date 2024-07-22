import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  static const String _customPathKey = 'custom_download_path';

  Future<String> get _defaultPath async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getDownloadsDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path;
    } else {
      final directory = await getDownloadsDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPathKey) ?? await _defaultPath;
  }

  Future<void> setCustomDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customPathKey, path);
  }

  Future<File> getLocalFile(String fileName) async {
    final path = await getDownloadPath();
    return File('$path/$fileName');
  }

  Future<String> writeContent(String fileName, List<int> bytes) async {
    try {
      final file = await getLocalFile(fileName);
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('Error writing file: $e');
      return '';
    }
  }
}