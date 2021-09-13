/*
import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';

import 'dart:developer' as developer;

/// Class to take in charge the responsibility of receiving and processing
/// the measurements taken from the device.
class MeasurementsCollector {
  static const String TAG = "MeasurementsCollector";

  late StreamSubscription<List<int>>? _subscription;

  void readMeasurements() async {
    List<BluetoothDevice> devices =
        await BluetoothBackend.getConnectedDevices();
    List<BluetoothCharacteristic> characteristics =
        await BluetoothBackend.getDevicesDataCollectionCharacteristics(devices);

    // TODO(https://git.io/JEyV4): Process data from more than one device.
    BluetoothCharacteristic characteristic = characteristics.first;
    await characteristic.setNotifyValue(true);
    _subscription = characteristic.value.listen((data) {
      // TODO(https://git.io/JEyVE): Format files with Edge Impulse's data acquisition format.
      // TODO(https://git.io/JEywB): Parse the incoming bytes.
      String measurement = new String.fromCharCodes(data);
      developer.log("Incoming data: $measurement", name: TAG);
    }, onError: (err) {
      developer.log("Error happened: ${err.toString()}", name: TAG);
    }, onDone: () {
      developer.log("Reading measurements done", name: TAG);
    });
  }

  void stopReadings() {
    if (_subscription != null) {
      _subscription!.cancel();
      developer.log("Subscription canceled.", name: TAG);
    }
  }
}
*/
