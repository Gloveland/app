
import 'dart:convert';

import 'package:flutter/material.dart';
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
  ///
  /// @param devicesSnapshot: snapshot of the devices currently connected via
  ///   bluetooth.
  static void sendCommandToConnectedDevices(
      AsyncSnapshot<List<BluetoothDevice>> devicesSnapshot,
      String command) async {
    List<BluetoothCharacteristic> characteristics =
    await BluetoothBackend.getMeasurementCharacteristics(devicesSnapshot);
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
  ///
  /// @param devicesSnapshot: snapshot of the devices currently connected via
  ///   bluetooth.
  static Future<List<BluetoothCharacteristic>> getMeasurementCharacteristics(
      AsyncSnapshot<List<BluetoothDevice>> devicesSnapshot) async {
    List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
    for (var device in devicesSnapshot.data!) {
      BluetoothService service = await getMeasurementService(device);
      BluetoothCharacteristic measurementCharacteristic =
      getMeasurementCharacteristic(service);
      characteristics.add(measurementCharacteristic);
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
  static Future<BluetoothService> getMeasurementService(
      BluetoothDevice bluetoothDevice) async {
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    return services.where((service) {
      developer.log("Service uuid: ${service.uuid.toString()}", name: TAG);
      return service.uuid.toString() ==
          BluetoothSpecification.MEASUREMENTS_SERVICE_UUID;
    }).first;
  }
}
