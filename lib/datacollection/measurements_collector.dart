import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/datacollection/measurements_writer.dart';
import 'dart:developer' as developer;
import 'package:lsa_gloves/model/glove_measurement.dart';

/// Class to take in charge the responsibility of receiving and processing
/// the measurements taken from the device.
class MeasurementsCollector {
  static const String TAG = "MeasurementsCollector";

  List<StreamSubscription<List<int>>> _subscriptions;
  MeasurementsWriter _measurementsWriter = MeasurementsWriter();
  List<MeasurementsListener> _listeners = [];
  MeasurementsCollector() : this._subscriptions = [] {
    _listeners.add(_measurementsWriter);
  }

  /// Starts collecting measurements from all the connected devices.
  ///
  /// A measurements file will be generated for each device with its
  /// collected measurements.
  void startCollecting(
      String gesture,
      Map<BluetoothDevice, BluetoothCharacteristic>
          dataCollectionCharacteristics) async {
    _resetState();
    _measurementsWriter.initialize(dataCollectionCharacteristics.keys, gesture);
    for (MapEntry<BluetoothDevice, BluetoothCharacteristic> entry
        in dataCollectionCharacteristics.entries) {
      BluetoothDevice device = entry.key;
      developer.log(
          "${device.name} [${device.id.id}] Starting collection gesture '$gesture'",
          name: TAG);
      _collectMeasurements(device.id.id, entry.value);
    }
  }

  void subscribeListener(MeasurementsListener listener) {
    _listeners.add(listener);
  }

  void unsubscribeListener(MeasurementsListener listener) {
    _listeners.remove(listener);
  }

  void saveCollection() {
    _measurementsWriter.saveCollection();
    _resetState();
  }

  /// Discards an ongoing collection, removing the generated files.
  void discardCollection() {
    _measurementsWriter.discardCollection();
    _resetState();
  }

  void _resetState() {
    _cancelSubscriptions();
  }

  void _cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions = [];
  }

  void _collectMeasurements(String deviceId,
      BluetoothCharacteristic dataCollectionCharacteristic) async {
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
      try {
        developer.log('Attempting to parse');
        GloveMeasurement gloveMeasurement =
            GloveMeasurement.fromFingerMeasurementsList(
                parsedMeasurements.eventNumber,
                parsedMeasurements.elapsedTime,
                deviceId,
                parsedMeasurements.values);
        developer.log('map to -> ${gloveMeasurement.toJson().toString()}');
        _notifyListeners(gloveMeasurement);
      } catch (e) {
        developer
            .log('cant parse : $parsedMeasurements  error : ${e.toString()}');
      }
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
    if (fingerMeasurements.length < 7) {
      developer.log(
          "Fewer measurements than expected: (${fingerMeasurements.length}).",
          name: TAG);
      return null;
    }
    int eventNum = int.parse(fingerMeasurements.removeAt(0));
    double elapsedTime = double.parse(fingerMeasurements.removeAt(0));
    return _ParsedMeasurements(eventNum, elapsedTime,  fingerMeasurements);
  }

  void _notifyListeners(GloveMeasurement measurement) {
    for (var listener in _listeners) {
      listener.onMeasurement(measurement);
    }
  }
}

class _ParsedMeasurements {
  final int eventNumber;
  final double elapsedTime;
  final List<String> values;

  _ParsedMeasurements(this.eventNumber, this.elapsedTime, this.values);

  @override
  String toString() {
    return values.toString();
  }
}
