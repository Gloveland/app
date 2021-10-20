import 'dart:async';
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

  void handleRawData(data, EventSink sink) {
    String rawMeasurement = new String.fromCharCodes(data);
    developer.log("Incoming data: $rawMeasurement", name: TAG);
    _ParsedMeasurement? parsedMeasurement =
        _parseRawMeasurement(rawMeasurement);
    sink.add(parsedMeasurement);
  }

  void _collectMeasurements(String deviceId,
      BluetoothCharacteristic dataCollectionCharacteristic) async {
    StreamTransformer imuSensorMeasurementsTransformer =
        new StreamTransformer.fromHandlers(handleData: this.handleRawData);

    subscription = dataCollectionCharacteristic.value
        .transform(imuSensorMeasurementsTransformer)
        .transform(ScanStreamTransformer((glove, parsedMeasurement, i) => acc + curr, 0))
        .listen((data) {
      String rawMeasurement = new String.fromCharCodes(data);
      developer.log("Incoming data: $rawMeasurement", name: TAG);
      _ParsedMeasurement? parsedMeasurement =
          _parseRawMeasurement(rawMeasurement);
      if (parsedMeasurement == null) {
        developer.log("Measurement parsing failed.", name: TAG);
        return;
      }
      try {
        developer.log('Attempting to parse');
        GloveMeasurement gloveMeasurement =
            GloveMeasurement.fromFingerMeasurementsList(
                parsedMeasurement.eventNumber,
                parsedMeasurement.elapsedTime,
                deviceId,
                parsedMeasurement.values);
        developer.log('map to -> ${gloveMeasurement.toJson().toString()}');
        _notifyListeners(gloveMeasurement);
      } catch (e) {
        developer
            .log('cant parse : $parsedMeasurement  error : ${e.toString()}');
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
  _ParsedMeasurement? _parseRawMeasurement(String rawMeasurements) {
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
    return _ParsedMeasurement(
        eventNum, elapsedTime, fingerFirstLetter, fingerMeasurements);
  }

  void _notifyListeners(GloveMeasurement measurement) {
    for (var listener in _listeners) {
      listener.onMeasurement(measurement);
    }
  }
}

class _ParsedMeasurement {
  final int eventNumber;
  final double elapsedTime;
  final String fingerFistLetter;
  final List<String> values;

  _ParsedMeasurement(
      this.eventNumber, this.elapsedTime, this.fingerFistLetter, this.values);

  @override
  String toString() {
    return values.toString();
  }
}
