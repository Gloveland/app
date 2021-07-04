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

  Future<List<MeasurementsFile>> getListOfFiles() async {
    var fileList = <MeasurementsFile>[];
    var completer = Completer<List<MeasurementsFile>>();
    final dir = await getApplicationDocumentsDirectory();
    var lister = dir.list(recursive: false);
    lister.where((entity) => entity is File)
        .asyncMap((f) async => MeasurementsFile(f as File, await f.lastModified()))
        .listen((measurementsFile) => fileList.add(measurementsFile),
        onDone:  () => completer.complete(fileList),
        onError: (error) => print("error getting files: "+ error),
    );
    return completer.future;
  }

  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: false);
    lister.listen (
            (file) => files.add(file),
        // should also register onError
        onDone:   () => completer.complete(files)
    );
    return completer.future;
  }

  Future<File> createFile(String name) async {
    final path = await _localPath;
    return File('$path/$name.txt');
  }
}

class MeasurementsFile {
  final File file;
  final DateTime lasModificationDate;

  String get path => file.path;

  String get lastModified => "$lasModificationDate";
  

  MeasurementsFile(
        this.file,
        this.lasModificationDate);

  Future<File> writeSensorMeasurementRow(String row) async {
    //TODO proteger concunrrencia, mutex??
    return this.file.writeAsString(row, mode: FileMode.append);
  }


  Future<String> readSensorMeasurements() async {
    try {
      //TODO proteger concunrrencia, mutex??
      final contents = await file.readAsString();
      return  contents;
    } catch (e) {
      return ""; // If encountering an error, return empty string
    }
  }

  Future deleteFile() async {
    try {
      await file.delete();
      print("file deleted");
    } catch (e) {
      print("cant delete file");
    }
  }
}
