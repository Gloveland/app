import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:developer' as developer;

import 'bluetooth_specification.dart';

/// Wrapper class to handle the communication between the app and the devices.
class BluetoothBackend {
  static const String TAG = "BluetoothBackend";

  /// Retrieves the connected devices.
  static Future<List<BluetoothDevice>> getConnectedDevices() {
    return FlutterBlue.instance.connectedDevices;
  }

  /// Sends the commands specified as a parameter to the connected devices
  /// through the measurements characteristic.
  ///
  /// This method is expected to be used to start and stop the measurement
  /// readings from the glove.
  static void sendCommandToConnectedDevices(String command) async {
    List<BluetoothDevice> connectedDevices = await getConnectedDevices();
    List<BluetoothCharacteristic> characteristics =
        await BluetoothBackend.getMeasurementCharacteristics(connectedDevices);
    characteristics.forEach((characteristic) async {
      try {
        await characteristic.write(utf8.encode(command), withoutResponse: true);
      } catch (err) {
        developer.log("Characteristic write failed: " + err.toString(),
            name: TAG);
      }
    });
  }

  /// Retrieves the measurement characteristics of all the connected devices.
  ///
  /// By retrieving all the measurement characteristics of the connected devices
  /// (expected to be one characteristic each) we can then broadcast a command
  /// to all of them.
  static Future<List<BluetoothCharacteristic>> getMeasurementCharacteristics(
      List<BluetoothDevice> devicesSnapshot) async {
    List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
    for (var device in devicesSnapshot) {
      BluetoothService? service = await getMeasurementService(device);
      if (service != null) {
        BluetoothCharacteristic measurementCharacteristic =
        getMeasurementCharacteristic(service);
        characteristics.add(measurementCharacteristic);
      }
    }
    developer.log("Measurement characteristics: $characteristics", name: TAG);
    return characteristics;
  }

  /// Retrieves the measurement characteristic from the {@code bluetoothService}
  /// specified.
  static BluetoothCharacteristic getMeasurementCharacteristic(
      BluetoothService bluetoothService) {
    return bluetoothService.characteristics
        .where((characteristic) =>
            characteristic.uuid.toString() ==
            BluetoothSpecification.MEASUREMENTS_CHARACTERISTIC_UUID)
        .first;
  }

  /// Retrieves the measurement service from the specified device.
  static Future<BluetoothService?> getMeasurementService(
      BluetoothDevice bluetoothDevice) async {
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    return services.firstWhereOrNull((service) {
      developer.log("Service uuid: ${service.uuid.toString()}", name: TAG);
      return service.uuid.toString() ==
          BluetoothSpecification.MEASUREMENTS_SERVICE_UUID;
    });
  }
}
