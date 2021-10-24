import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/datacollection/measurements_writer.dart';
import 'dart:developer' as developer;
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:rxdart/rxdart.dart';

/// Class to take in charge the responsibility of receiving and processing
/// the measurements taken from the device.
class MeasurementsCollector {
  static const String TAG = "MeasurementsCollector";

  List<StreamSubscription<List<ParsedMeasurement>>> _subscriptions;
  MeasurementsWriter? _measurementsWriter;
  List<MeasurementsListener> _listeners = [];
  MeasurementsCollector(bool writeToFile) : this._subscriptions = [] {
    if (writeToFile) {
      _measurementsWriter = MeasurementsWriter();
      _listeners.add(_measurementsWriter!);
    }
  }

  void startTestCollection(Map<BluetoothDevice, BluetoothCharacteristic> dataCollectionCharacteristics) {
    startCollecting("Test", dataCollectionCharacteristics);
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
    _measurementsWriter?.initialize(dataCollectionCharacteristics.keys, gesture);
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
    _measurementsWriter?.saveCollection();
    _resetState();
  }

  /// Discards an ongoing collection, removing the generated files.
  void discardCollection() {
    _measurementsWriter?.discardCollection();
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

  void handleRawData(data, EventSink sink) {
    String rawMeasurement = new String.fromCharCodes(data);
    ParsedMeasurement? parsedMeasurement =
        _parseRawMeasurement(rawMeasurement);
    if (parsedMeasurement == null) {
      developer.log("Measurement parsing failed.", name: TAG);
      return;
    }
    sink.add(parsedMeasurement);
  }

  void _collectMeasurements(String deviceId,
      BluetoothCharacteristic dataCollectionCharacteristic) async {
    StreamTransformer<List<int>,ParsedMeasurement> imuSensorMeasurementsTransformer =
        new StreamTransformer.fromHandlers(handleData: this.handleRawData);

    InclinationCalculator inclinationCalculator = InclinationCalculator();

    var subscription = dataCollectionCharacteristic.value
        .transform(imuSensorMeasurementsTransformer)
        .transform(ScanStreamTransformer<ParsedMeasurement, List<ParsedMeasurement>>((measurementList, parsedMeasurement, i) {
          if(measurementList!.length < 5 ){
            var fingerLetter = parsedMeasurement.fingerFistLetter;
            if(expectedFingerOrder(measurementList.length) == fingerLetter){
              measurementList.add(parsedMeasurement);
              return measurementList;
            }
          }
          return [];
    }, []))
    .where((measurementList) => measurementList.length == 5)
        .listen((measurementList) {
      try {
        GloveMeasurement gloveMeasurement =
            GloveMeasurement.fromFingerMeasurementsList(
                deviceId,
                measurementList, inclinationCalculator);
        developer.log('map to -> ${gloveMeasurement.toJson().toString()}');
        _notifyListeners(gloveMeasurement);
      } catch (e) {
        developer
            .log('cant create GloveMeasurements : $measurementList  error : ${e.toString()}', name: TAG);
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
  ParsedMeasurement? _parseRawMeasurement(String rawMeasurements) {
    if (rawMeasurements.isEmpty) {
      developer.log("Raw measurements was an empty string!", name: TAG);
      return null;
    }

    List<String> fingerMeasurements =
        rawMeasurements.split(',').where((s) => s.isNotEmpty).toList();
    if (fingerMeasurements.length < 9) {
      developer.log(
          "Fewer measurements than expected: (${fingerMeasurements.length}).",
          name: TAG);
      return null;
    }
    int eventNum = int.parse(fingerMeasurements.removeAt(0));
    double elapsedTime = double.parse(fingerMeasurements.removeAt(0));
    String fingerFirstLetter = fingerMeasurements.removeAt(0);
    var values = fingerMeasurements.map((val) => double.parse(val)).toList();
    return ParsedMeasurement(
        eventNum, elapsedTime, fingerFirstLetter,values);
  }

  void _notifyListeners(GloveMeasurement measurement) {
    for (var listener in _listeners) {
      listener.onMeasurement(measurement);
    }
  }

  @override
  void dispose() {
    this._resetState();

  }

  expectedFingerOrder(int index) {
    switch(index){
      case 0:
        return 'P';
      case 1:
        return 'R';
      case 2:
        return 'M';
      case 3:
        return 'I';
      case 4:
        return 'T';
      default:
        return '';
    }
  }
}

class ParsedMeasurement {
  final int eventNumber;
  final double elapsedTime;
  final String fingerFistLetter;
  final List<double> values;

  ParsedMeasurement(
      this.eventNumber, this.elapsedTime, this.fingerFistLetter, this.values);

  @override
  String toString() {
    return values.toString();
  }
}
