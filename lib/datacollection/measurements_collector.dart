import 'dart:async';
import 'dart:io';

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
  List<StreamSubscription<List<int>>?> _subscriptions = [];

  /// Starts collecting measurements from all the connected devices.
  ///
  /// A measurements file will be generated for each device with its
  /// collected measurements.
  void startCollecting(List<BluetoothDevice> connectedDevices, String gesture) async {
    developer.log("Starting collection for gesture '$gesture' from devices: $connectedDevices", name: TAG);
    _resetState();
    for (BluetoothDevice device in connectedDevices) {
      BluetoothService? lsaService =
          await BluetoothBackend.getLsaGlovesService(device);
      BluetoothCharacteristic dcCharacteristic =
          BluetoothBackend.getDataCollectionCharacteristic(lsaService!);
      _initFile(device.id.id, gesture);
      _collectMeasurements(device.id.id, dcCharacteristic);
      sleep(Duration(milliseconds: 1000));
    }
  }

  /// Saves the collection files and stops recording measurements.

  void saveCollection() async {
    _cancelSubscriptions();
    for (var measurementsFile in _deviceMeasurements.values) {
      await measurementsFile.save();
    }
    _deviceMeasurements.clear();
  }
  /// Discards an ongoing collection, removing the generated files.

  void discardCollection() async {
    _resetState();
  }

  void _initFile(String deviceId, String gesture) async {
    DeviceMeasurementsFile deviceMeasurementsFile
        = await DeviceMeasurementsFile.create(deviceId, gesture);
    _deviceMeasurements.putIfAbsent(deviceId, () => deviceMeasurementsFile);
  }

  void _resetState() {
    _cancelSubscriptions();
    _deviceMeasurements.clear();
  }

  void _cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription?.cancel();
    }
    _subscriptions = [];
  }

  void _collectMeasurements(String deviceId,
      BluetoothCharacteristic dataCollectionCharacteristic) async {
    if (!dataCollectionCharacteristic.isNotifying) {
      await dataCollectionCharacteristic.setNotifyValue(true);
    }
    StreamSubscription<List<int>> subscription =
        dataCollectionCharacteristic.value.listen((data) {
      String rawMeasurements = new String.fromCharCodes(data);
      developer.log("Incoming data: $rawMeasurements", name: TAG);
      _ParsedMeasurements? parsedMeasurements =
          _parseRawMeasurements(rawMeasurements);
      if (parsedMeasurements == null) {
        developer.log("Measurements parsing failed.", name: TAG);
        return;
      }
      _recordParsedMeasurement(deviceId, parsedMeasurements.eventNumber, parsedMeasurements.values);
    }, onError: (err) {
      developer.log("Error: ${err.toString()}", name: TAG);
    }, onDone: () {
      developer.log("Reading measurements done", name: TAG);
    });
    _subscriptions.add(subscription);
  }

  /// Parses the raw measurements passed as a parameter.
  ///
  /// Returns a ParsedMeasurements instance containing the event number and a
  /// list of float measurements represented as strings.
  /// In case the parsing failed, null is returned.
  _ParsedMeasurements? _parseRawMeasurements(String rawMeasurements) {
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
    return _ParsedMeasurements(eventNum, fingerMeasurements);
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
}

class _ParsedMeasurements {
  final int eventNumber;
  final List<String> values;
  
  _ParsedMeasurements(this.eventNumber, this.values);
}
