import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';

/// Writer class to receive GloveMeasurements and store them into files.
class MeasurementsWriter with MeasurementsListener {
  Map<String, DeviceMeasurementsFile> _deviceMeasurements;

  MeasurementsWriter() : this._deviceMeasurements = Map();

  void initialize(Iterable<BluetoothDevice> devices, String gesture) {
    _deviceMeasurements.clear();
    devices.forEach((device) {_initFile(device.name, device.id.id, gesture);});
  }

  @override
  void onMeasurement(GloveMeasurement measurement) {
    String deviceId = measurement.deviceId;
    _deviceMeasurements[deviceId]?.add(measurement);
  }

  /// Saves the collection files and stops recording measurements.
  void saveCollection() async {
    for (var measurementsFile in _deviceMeasurements.values) {
      await measurementsFile.save();
    }
    _deviceMeasurements.clear();
  }

  void discardCollection() async {
    //TODO: create files and write upon receiving events and delete them here
    //in case the collection has to be discarded.
    _deviceMeasurements.clear();
  }

  void _initFile(String deviceName, String deviceId, String gesture) async {
    DeviceMeasurementsFile deviceMeasurementsFile =
    await DeviceMeasurementsFile.create(deviceName, deviceId, gesture);
    _deviceMeasurements.putIfAbsent(deviceId, () => deviceMeasurementsFile);
  }
}