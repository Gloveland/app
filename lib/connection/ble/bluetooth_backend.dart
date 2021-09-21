import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:developer' as developer;

import 'bluetooth_specification.dart';

/// Wrapper class to handle the communication between the app and the devices.
class BluetoothBackend {
  static const String TAG = "BluetoothBackend";
  static const String RightGlove = "Guante derecho";
  static const String LeftGlove = "Guante izquierdo";

  /// Retrieves the connected devices.
  static Future<List<BluetoothDevice>> getConnectedDevices() {
    return FlutterBlue.instance.connectedDevices;
  }

  static void sendStartDataCollectionCommand(List<BluetoothDevice> connectedDevices) async {
    sendCommandToConnectedDevices(connectedDevices, BluetoothSpecification.START_DATA_COLLECTION);
  }

  static void sendStartInterpretationCommand(List<BluetoothDevice> connectedDevices) async {
    sendCommandToConnectedDevices(connectedDevices, BluetoothSpecification.START_INTERPRETATIONS);
  }

  static void sendStopCommand(List<BluetoothDevice> connectedDevices) async {
    sendCommandToConnectedDevices(connectedDevices,BluetoothSpecification.STOP_ONGOING_TASK);
  }

  /// Sends the commands specified as a parameter to the connected devices
  /// through the control characteristic.
  ///
  /// This method is expected to be used to start and stop the measurement
  /// readings from the glove as well as the interpretations.
  static void sendCommandToConnectedDevices(List<BluetoothDevice> connectedDevices, String command) async {
    List<BluetoothCharacteristic> characteristics =
        await getDevicesControllerCharacteristics(connectedDevices);
    characteristics.forEach((characteristic) async {
      try {
        await characteristic.write(utf8.encode(command), withoutResponse: true);
      } catch (err) {
        developer.log("Characteristic write failed: " + err.toString(),
            name: TAG);
      }
    });
  }

  /// Retrieves the LSA glove service from the specified device.
  static Future<BluetoothService?> getLsaGlovesService(
      BluetoothDevice bluetoothDevice) async {
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    return services.firstWhereOrNull((service) {
      developer.log("Service uuid: ${service.uuid.toString()}", name: TAG);
      return service.uuid.toString() ==
          BluetoothSpecification.LSA_GLOVE_SERVICE_UUID;
    });
  }

  /// Retrieves the data collection characteristics of all the connected
  /// devices.
  static Future<List<BluetoothCharacteristic>>
      getDevicesDataCollectionCharacteristics(
          List<BluetoothDevice> devicesSnapshot) async {
    List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
    for (var device in devicesSnapshot) {
      BluetoothService? service = await getLsaGlovesService(device);
      if (service != null) {
        BluetoothCharacteristic dataCollectionCharacteristic =
            getDataCollectionCharacteristic(service);
        characteristics.add(dataCollectionCharacteristic);
      }
    }
    developer.log("Data collection characteristics: $characteristics",
        name: TAG);
    return characteristics;
  }

  /// Retrieves the data collection characteristic from the
  /// {@code bluetoothService} specified.
  static BluetoothCharacteristic getDataCollectionCharacteristic(
      BluetoothService bluetoothService) {
    return bluetoothService.characteristics.firstWhere((characteristic) =>
        characteristic.uuid.toString() ==
        BluetoothSpecification.DATA_COLLECTION_CHARACTERISTIC_UUID);
  }

  /// Retrieves the controller characteristic from the {@code bluetoothService}
  /// specified.
  static BluetoothCharacteristic getControllerCharacteristic(
      BluetoothService bluetoothService) {
    return bluetoothService.characteristics.firstWhere((characteristic) =>
        characteristic.uuid.toString() ==
        BluetoothSpecification.CONTROLLER_CHARACTERISTIC_UUID);
  }

  /// Retrieves the controller characteristics of all the connected devices.
  ///
  /// By retrieving all the controller characteristics of the connected
  /// devices (expected to be one characteristic each) we can then broadcast a
  /// command to all of them.
  static Future<List<BluetoothCharacteristic>>
      getDevicesControllerCharacteristics(
          List<BluetoothDevice> devicesSnapshot) async {
    List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
    for (var device in devicesSnapshot) {
      BluetoothService? service = await getLsaGlovesService(device);
      if (service != null) {
        BluetoothCharacteristic controllerCharacteristic =
            getControllerCharacteristic(service);
        characteristics.add(controllerCharacteristic);
      }
    }
    developer.log("Controller characteristics: $characteristics", name: TAG);
    return characteristics;
  }

  /// Retrieves the interpretation characteristic from the {@code bluetoothService}
  /// specified.
  static BluetoothCharacteristic getInterpretationCharacteristic(
      BluetoothService bluetoothService) {
    return bluetoothService.characteristics.firstWhere((characteristic) =>
        characteristic.uuid.toString() ==
        BluetoothSpecification.INTERPRETATION_CHARACTERISTIC_UUID);
  }

  /// Retrieves the interpretation characteristics of all the connected devices.
  static Future<List<BluetoothCharacteristic>>
      getDevicesInterpretationCharacteristics(
          List<BluetoothDevice> devicesSnapshot) async {
    List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
    for (var device in devicesSnapshot) {
      BluetoothService? service = await getLsaGlovesService(device);
      if (service != null) {
        BluetoothCharacteristic interpretationCharacteristic =
            getInterpretationCharacteristic(service);
        characteristics.add(interpretationCharacteristic);
      }
    }
    developer.log("Interpretation characteristics: $characteristics",
        name: TAG);
    return characteristics;
  }

  /// Retrieve the deviceName in spanish
  static String getSpanishGloveName(String deviceName){
    switch(deviceName){
      case(BluetoothSpecification.deviceName):
        return RightGlove;
      default:
        return deviceName;
    }

  }


}
