import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GloveEventsStorage {

  static final GloveEventsStorage _singleton = GloveEventsStorage._internal();

  factory GloveEventsStorage() {
    return _singleton;
  }

  GloveEventsStorage._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/file1.txt');
  }

  Future<String> readMeasurements() async {
    try {
      final file = await _localFile;
      // Read the file
      //TODO proteger concunrrencia, mutex??
      final contents = await file.readAsString();
      return  contents;
    } catch (e) {
      // If encountering an error, return 0
      return "";
    }
  }

  Future<File> writeSensorMeasurementRow(String row) async {
    final file = await _localFile;
    var realPath = file.path;
    print("File realpath: $realPath");
    // Write the file
    //TODO proteger concunrrencia, mutex??
    return file.writeAsString(row, mode: FileMode.append);
  }
}
