import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/storage.dart';

import 'dart:developer' as developer;

import 'package:lsa_gloves/model/glove_measurement.dart';

/// Class to take in charge the responsibility of receiving and processing
/// the measurements taken from the device.
class MeasurementsCollector {
  static const String TAG = "MeasurementsCollector";

  Map<String, DeviceMeasurementsFile> _deviceMeasurements = Map();
  bool isRecording = false;
  List<StreamSubscription<List<int>>?> _subscriptions = [];

  /// Starts collecting measurements from all the connected devices.
  ///
  /// A measurements file will be generated for each device with its
  /// collected measurements.
  void startCollection(List<BluetoothDevice> connectedDevices, String gesture) async {
    developer.log("Starting collection for gesture '$gesture' from devices: $connectedDevices", name: TAG);
    for (BluetoothDevice device in connectedDevices) {
      BluetoothService? lsaService =
          await BluetoothBackend.getLsaGlovesService(device);
      BluetoothCharacteristic dcCharacteristic =
          BluetoothBackend.getDataCollectionCharacteristic(lsaService!);
      initFile(device.id.id, gesture);
      collectMeasurements(device.id.id, dcCharacteristic);
    }
    isRecording = true;
  }

  void initFile(String deviceId, String gesture) async {
    DeviceMeasurementsFile deviceMeasurementsFile
        = await DeviceMeasurementsFile.create(deviceId, gesture);
    _deviceMeasurements.putIfAbsent(deviceId, () => deviceMeasurementsFile);
  }

  /// Saves the collection files and stops recording measurements.
  void saveCollection() async {
    _cancelSubscriptions();
    for (var measurementsFile in _deviceMeasurements.values) {
      await measurementsFile.save();
    }
    _deviceMeasurements.clear();
    isRecording = false;
  }

  /// Discards an ongoing collection, removing the generated files.
  void discardCollection() async {
    _cancelSubscriptions();
    for (var measurementsFile in _deviceMeasurements.values) {
      await measurementsFile.deleteFile();
    }
    _deviceMeasurements.clear();
    isRecording = false;
  }

  void _cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription?.cancel();
    }
    _subscriptions = [];
  }

  void collectMeasurements(String deviceId,
      BluetoothCharacteristic dataCollectionCharacteristic) async {
    if (!dataCollectionCharacteristic.isNotifying) {
      await dataCollectionCharacteristic.setNotifyValue(true);
    }
    StreamSubscription<List<int>> subscription =
        dataCollectionCharacteristic.value.listen((data) {
      String rawMeasurements = new String.fromCharCodes(data);
      developer.log("Incoming data: $rawMeasurements", name: TAG);
      Pair<int, List<String>>? parsedMeasurements =
          _parseRawMeasurements(rawMeasurements);
      if (parsedMeasurements == null) {
        developer.log("Measurements parsing failed.", name: TAG);
        return;
      }
      var eventNum = parsedMeasurements.first;
      _recordParsedMeasurement(deviceId, eventNum, parsedMeasurements.second);
    }, onError: (err) {
      developer.log("Error: ${err.toString()}", name: TAG);
    }, onDone: () {
      developer.log("Reading measurements done", name: TAG);
    });
    _subscriptions.add(subscription);
  }

  /// Parses the raw measurements passed as a parameter.
  ///
  /// Returns a pair containing:
  ///   - first: the event number.
  ///   - second: a list of float measurements represented as strings.
  Pair<int, List<String>>? _parseRawMeasurements(String rawMeasurements) {
    if (rawMeasurements.isEmpty) {
      developer.log("Raw measurements was an empty string!", name: TAG);
      return null;
    }
    var lastCharacter = rawMeasurements.substring(rawMeasurements.length - 1);
    if (lastCharacter != ";") {
      developer.log(
          "Last character is not the expected delimiter ';'. Verify the MTU is set properly.",
          name: TAG);
      return null;
    }

    List<String> fingerMeasurements = rawMeasurements
        .substring(0, rawMeasurements.length - 1)
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
    if (fingerMeasurements.length < 6) {
      developer.log(
          "Fewer measurements than expected: (${fingerMeasurements.length}).",
          name: TAG);
      return null;
    }
    int eventNum = int.parse(fingerMeasurements.removeAt(0));
    return Pair(eventNum, fingerMeasurements);
  }

  _recordParsedMeasurement(String deviceId, int eventNumber, List<String> measurements) {
    try {
      developer.log('Attempting to parse');
      GloveMeasurement gloveMeasurement = GloveMeasurement.fromFingerMeasurementsList(
          eventNumber, deviceId, measurements);
      developer.log('map to -> ${gloveMeasurement.toJson().toString()}');
      _deviceMeasurements[deviceId]?.add(gloveMeasurement);
    } catch (e) {
      developer.log('cant parse : $measurements  error : ${e.toString()}');
    }
  }
  
  // _stopReadings(BuildContext context, String selectedGesture) async {
  //   if (this._subscription != null) {
  //     this._subscription!.cancel();
  //     this._subscription = null;
  //     developer.log("Subscription canceled.", name: TAG);
  //   }
  //   if (_items.isNotEmpty) {
  //     _saveMessagesInFile(context, selectedGesture, this._items);
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("Movimientos guardados!"),
  //         duration: Duration(seconds: 1)));
  //   } else {
  //     developer.log("Empty measurment list, nothing to save", name: TAG);
  //   }
  //   await _characteristic.setNotifyValue(false);
  // }
  //
  // _saveMessagesInFile(BuildContext context, String selectedGesture,
  //     List<GloveMeasurement> gloveMeasurements) async {
  //   if (gloveMeasurements.isEmpty) {
  //     return;
  //   }
  //   //open pop up loading
  //   Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
  //   var deviceId = gloveMeasurements.first.deviceId;
  //   var measurementFile =
  //       await DeviceMeasurementsFile.create(deviceId, selectedGesture);
  //   for (int i = 0; i < gloveMeasurements.length; i++) {
  //     developer
  //         .log('saving in file -> ${gloveMeasurements[i].toJson().toString()}');
  //     measurementFile.add(gloveMeasurements[i]);
  //   }
  //   await measurementFile.save();
  //   this._items = [];
  //   //close pop up loading
  //   Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop();
  // }
}

class Pair<T, Q> {
  final T first;
  final Q second;

  Pair(this.first, this.second);

  @override
  String toString() => 'Pair[$first, $second]';
}