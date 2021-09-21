import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/edgeimpulse/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

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
        onError: (error) => developer.log("error getting datacollection: "+ error),
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

  Future<bool> add(GloveMeasurement measurement) async {
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
      developer.log("saving $json");
      await this.file.writeAsString(json);
      return true;
    } catch (e) {
      developer.log("error saving content to file"+ e.toString());
      return false;
    }
  }

  Future deleteFile() async {
    try {
      await file.delete();
      developer.log("file deleted");
    } catch (e) {
      developer.log("cant delete file");
    }
  }

  Future<String> _readAllAsString() async {
    try {
      //TODO proteger concunrrencia, mutex??
      final contents = await file.readAsString();
      return  contents;
    } catch (e) {
      developer.log("error reading content to file"+ e.toString());
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

  bool add(GloveMeasurement gloveMeasurement) {
    if(gloveMeasurement.deviceId != this.deviceId){
      developer.log("wrong deviceId $gloveMeasurement.deviceId");
      return false;
    }
    List<double> measurementList = [];
    addFingerMovements(measurementList, gloveMeasurement.pinky);
    addFingerMovements(measurementList, gloveMeasurement.ring);
    addFingerMovements(measurementList, gloveMeasurement.middle);
    addFingerMovements(measurementList, gloveMeasurement.index);
    addFingerMovements(measurementList, gloveMeasurement.thumb);
    this.values.add(measurementList);
    return true;
  }

  bool addFingerMovements(measurementList, Finger finger){
    measurementList.add(finger.acc.x);
    measurementList.add(finger.acc.y);
    measurementList.add(finger.acc.z);
    measurementList.add(finger.gyro.x);
    measurementList.add(finger.gyro.y);
    measurementList.add(finger.gyro.z);
    measurementList.add(finger.inclination.roll);
    measurementList.add(finger.inclination.pitch);
    measurementList.add(finger.inclination.yaw);
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
