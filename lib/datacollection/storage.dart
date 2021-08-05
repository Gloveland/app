import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:lsa_gloves/model/movement.dart';
import 'package:lsa_gloves/edgeimpulse/api_client.dart';
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

  Future<List<DeviceMeasurementsFile>> getListOfFiles() async {
    var fileList = <DeviceMeasurementsFile>[];
    var completer = Completer<List<DeviceMeasurementsFile>>();
    final dir = await getApplicationDocumentsDirectory();
    var lister = dir.list(recursive: false);
    lister.where((entity) => entity is File)
        .asyncMap((f) async => DeviceMeasurementsFile.fromFileSystem(f as File, await f.lastModified()))
        .listen((measurementsFile) => fileList.add(measurementsFile),
        onDone:  () => completer.complete(fileList),
        onError: (error) => print("error getting datacollection: "+ error),
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
    return File('$path/$name.json');
  }
}

class DeviceMeasurementsFile {
  final File file;
  final DateTime lastModificationDate;
  SensorMeasurements? fileContent;
  
  String get path => file.path;
  String get lastModified => "$lastModificationDate";
  

  DeviceMeasurementsFile._(
      this.file,
      this.lastModificationDate,
      this.fileContent);

  static Future<DeviceMeasurementsFile> create(String deviceId, String word) async {
    var creationDate = DateTime.now();
    var values = <List<double>>[];
    SensorMeasurements json = new SensorMeasurements(deviceId, word, values);
    String datetimeStr = format(creationDate);
    var filename = "${word}_$datetimeStr";
    var file = await new GloveEventsStorage().createFile(filename);
    return DeviceMeasurementsFile._(file, creationDate, json);
  }

  Future<bool> add(Movement measurement) async {
    if(this.fileContent == null){
      this.fileContent = await readJsonContent();
    }
    return this.fileContent!.add(measurement);
  }

  factory DeviceMeasurementsFile.fromFileSystem(file, lastModificationDate){
    return DeviceMeasurementsFile._(file, lastModificationDate, null);
  }

  Future<bool> save() async {
    try {
      //TODO proteger concunrrencia, mutex??
      String json = jsonEncode(this.fileContent);
      print("saving $json");
      await this.file.writeAsString(json);
      return true;
    } catch (e) {
      print("error saving content to file"+ e.toString());
      return false;
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

  Future<String> _readAllAsString() async {
    try {
      //TODO proteger concunrrencia, mutex??
      final contents = await file.readAsString();
      return  contents;
    } catch (e) {
      print("error reading content to file"+ e.toString());
      return ""; // If encountering an error, return empty string
    }
  }
  Future<SensorMeasurements> readJsonContent() async {
    String fileContent = await _readAllAsString();
    return SensorMeasurements.fromJson(json.decode(fileContent));
  }

  Future<void> upload() async {
    SensorMeasurements measurementsJson = await readJsonContent();
    uploadFile(measurementsJson, lastModificationDate);
  }

  static String format(DateTime date) {
    return "${date.day.toString().padLeft(2,'0')}-"+
        "${date.month.toString().padLeft(2,'0')}-" +
        "${date.year.toString()}_" +
        "${date.hour.toString()}:" +
        "${date.minute.toString()}:" +
        "${date.second.toString()}";
  }
}

class SensorMeasurements {
  final String deviceId;
  final String word;
  final List<List<double>> values;

  SensorMeasurements(this.deviceId, this.word, this.values);

  bool add(Movement mov) {
    if(mov.deviceId != this.deviceId){
      print("wrong deviceId $mov.deviceId");
      return false;
    }
    List<double> measurementList = [];
    var thump = mov.hand.thump;
    measurementList.add(thump.acc.x);
    measurementList.add(thump.acc.y);
    measurementList.add(thump.acc.z);
    measurementList.add(thump.gyro.x);
    measurementList.add(thump.gyro.y);
    measurementList.add(thump.gyro.z);
    measurementList.add(thump.inclination.yaw);
    measurementList.add(thump.inclination.pitch);
    measurementList.add(thump.inclination.roll);
    this.values.add(measurementList);
    return true;
  }

  factory SensorMeasurements.fromJson(dynamic json) {
    List<List<double>> _values = <List<double>>[];
    if (json['values'] != null) {
      var jsonLists = json['values'] as List;
      _values = jsonLists.map((jsonList) {
        var valuesList = jsonList as List;
        return valuesList.map((v) => v as double).toList();
      }).toList();
    }
    return SensorMeasurements(
      json['device_id'] as String,
      json['word'] as String,
      _values,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id': deviceId,
      'word': word,
      'values': values,
    };
  }


}
