import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/edgeimpulse/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

/// Class to manage the stored files with sensors measurements from the gloves.
class FileManager {
  static const String TAG = "FileManager";
  static final FileManager _singleton = FileManager._internal();

  factory FileManager() {
    return _singleton;
  }

  FileManager._internal();

  Future<String> get _localPath async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  Future<List<DeviceMeasurementsFile>> getListOfFiles() async {
    var fileList = <DeviceMeasurementsFile>[];
    var completer = Completer<List<DeviceMeasurementsFile>>();
    final dir = await getExternalStorageDirectory();
    var lister = dir!.list(recursive: false);
    lister
        .where((entity) => entity is File)
        .asyncMap((f) async => DeviceMeasurementsFile.fromFileSystem(
            f as File, await f.lastModified()))
        .listen(
          (measurementsFile) => fileList.add(measurementsFile),
          onDone: () => completer.complete(fileList),
          onError: (error) =>
              developer.log("error getting datacollection: " + error),
        );
    return completer.future;
  }

  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: false);
    lister.listen((file) => files.add(file),
        // should also register onError
        onDone: () => completer.complete(files));
    return completer.future;
  }

  Future<File> createFile(String name) async {
    final path = await _localPath;
    return File('$path/$name.json');
  }
}

/// Class to handle the storage of the received measurements in a json file.
class DeviceMeasurementsFile {
  static const TAG = "DeviceMeasurementsFile";
  final File file;
  final DateTime lastModificationDate;
  BufferedSensorMeasurements? fileContent;

  String get path => file.path;

  String get lastModified => "$lastModificationDate";

  DeviceMeasurementsFile._(
      this.file, this.lastModificationDate, this.fileContent);

  static Future<DeviceMeasurementsFile> create(
      String deviceName, String deviceId, String word) async {
    var creationDate = DateTime.now();
    BufferedSensorMeasurements json = new BufferedSensorMeasurements(
        deviceName, deviceId, word,  <List<double>>[], <int>[]);
    String datetimeStr = format(creationDate);
    var filename = "${deviceName.substring(0, 1)}_${word}_$datetimeStr";
    var file = await new FileManager().createFile(filename);
    return DeviceMeasurementsFile._(file, creationDate, json);
  }

  Future<bool> add(GloveMeasurement measurement) async {
    if (this.fileContent == null) {
      this.fileContent = await readJsonContent();
    }
    return this.fileContent!.add(measurement);
  }

  factory DeviceMeasurementsFile.fromFileSystem(file, lastModificationDate) {
    return DeviceMeasurementsFile._(file, lastModificationDate, null);
  }

  Future<bool> save() async {
    try {
      String json = jsonEncode(this.fileContent);
      developer.log("saving $json");
      await this.file.writeAsString(json);
      return true;
    } catch (e) {
      developer.log("error saving content to file" + e.toString());
      return false;
    }
  }

  Future deleteFile() async {
    try {
      await file.delete();
      developer.log("file deleted");
    } catch (e) {
      developer.log("Cant delete file: ${e.toString()}");
    }
  }

  Future<String> _readAllAsString() async {
    try {
      final contents = await file.readAsString();
      return contents;
    } catch (e) {
      developer.log("error reading content to file" + e.toString());
      return ""; // If encountering an error, return empty string
    }
  }

  Future<BufferedSensorMeasurements> readJsonContent() async {
    String fileContent = await _readAllAsString();
    return BufferedSensorMeasurements.fromJson(json.decode(fileContent));
  }

  Future<bool> upload() async {
    try {
      BufferedSensorMeasurements measurementsJson = await readJsonContent();
      return EdgeImpulseApiClient.uploadFile(
          measurementsJson, lastModificationDate);
    }catch(e, stacktrace) {
      developer.log(e.toString(), name: TAG);
      developer.log(stacktrace.toString(), name: TAG);
      return false;
    }
  }

  static String format(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-" +
        "${date.month.toString().padLeft(2, '0')}-" +
        "${date.year.toString()}_" +
        "${date.hour.toString()}:" +
        "${date.minute.toString()}:" +
        "${date.second.toString()}";
  }
}

/// Class to buffer the incoming sensor measurements in an internal list.
class BufferedSensorMeasurements {
  final String deviceName;
  final String deviceId;
  final String word;
  final List<int> timestamps;
  final List<List<double>> values;

  BufferedSensorMeasurements(this.deviceName, this.deviceId, this.word,this.values,
     this.timestamps);

  bool add(GloveMeasurement gloveMeasurement) {
    if (gloveMeasurement.deviceId != this.deviceId) {
      developer.log("wrong deviceId $gloveMeasurement.deviceId");
      return false;
    }
    List<double> measurementList = [];
    measurementList.addAll(extractFingerMeasurement(gloveMeasurement.thumb));
    measurementList.addAll(extractFingerMeasurement(gloveMeasurement.index));
    measurementList.addAll(extractFingerMeasurement(gloveMeasurement.middle));
    measurementList.addAll(extractFingerMeasurement(gloveMeasurement.ring));
    measurementList.addAll(extractFingerMeasurement(gloveMeasurement.pinky));

    this.values.add(measurementList);
    this.timestamps.add(gloveMeasurement.timestampMillis);
    return true;
  }

  List<double> extractFingerMeasurement(Finger finger) {
    List<double> measurementList = [];
    measurementList.add(finger.acc.x);
    measurementList.add(finger.acc.y);
    measurementList.add(finger.acc.z);
    measurementList.add(finger.gyro.x);
    measurementList.add(finger.gyro.y);
    measurementList.add(finger.gyro.z);
    return measurementList;
  }

  factory BufferedSensorMeasurements.fromJson(dynamic json) {
    List<List<double>> _values = <List<double>>[];
    List<int> _timestamps = <int>[];

    if (json['values'] != null) {
      var jsonLists = json['values'] as List;
      _values = jsonLists.map((jsonList) {
        var valuesList = jsonList as List;
        return valuesList.map((v) => v as double).toList();
      }).toList();
    }
    if (json['timestamps'] != null) {
      var jsonLists = json['timestamps'] as List;
      _timestamps = jsonLists.map((v) => v as int).toList();
    }
    return BufferedSensorMeasurements(
      json['device_name'] as String,
      json['device_id'] as String,
      json['word'] as String,
      _values,
      _timestamps,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_name': deviceName,
      'device_id': deviceId,
      'word': word,
      'measurements_amount': values.length,
      'values': values,
      'timestamps': timestamps
    };
  }
}
