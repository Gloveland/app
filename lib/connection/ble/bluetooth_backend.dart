import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:developer' as developer;

import 'bluetooth_specification.dart';

/// Wrapper class to handle the communication between the app and the devices.
class BluetoothBackend with ChangeNotifier {
  static const String TAG = "BluetoothBackend";
  static const String RightGlove = "Guante derecho";
  static const String LeftGlove = "Guante izquierdo";

  List<BluetoothDevice> _connectedDevices = [];
  Map<BluetoothDevice, BluetoothCharacteristic> _controllerCharacteristics =
      Map();
  Map<BluetoothDevice, BluetoothCharacteristic> _dataCollectionCharacteristics =
      Map();
  Map<BluetoothDevice, BluetoothCharacteristic> _interpretationCharacteristics =
      Map();

  List<BluetoothDevice> get connectedDevices => _connectedDevices;
  Map<BluetoothDevice, BluetoothCharacteristic>
      get controllerCharacteristics => _controllerCharacteristics;

  Map<BluetoothDevice, BluetoothCharacteristic>
      get dataCollectionCharacteristics => _dataCollectionCharacteristics;

  Map<BluetoothDevice, BluetoothCharacteristic>
      get interpretationCharacteristics => _interpretationCharacteristics;

  late Stream<List<BluetoothDevice>> connectedDevicesStream;

  BluetoothBackend() {
    _startMonitoringDevices();
  }

  /// Starts monitoring the connected devices and notifies the listeners of this
  /// class when a connection event (i.e. connection or disconnection) happens.
  void _startMonitoringDevices() {
    this.connectedDevicesStream = Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => BluetoothBackend.getConnectedDevices())
        .asBroadcastStream();
    this.connectedDevicesStream.listen((newConnectedDevices) async {
      if (this._connectedDevices.length != newConnectedDevices.length) {
        developer.log("Connection event.", name: TAG);
        _assertAnyDisconnection(
            this._connectedDevices, newConnectedDevices);
        this._connectedDevices = newConnectedDevices;
        _updateState(newConnectedDevices)
            .then((_) => _requestMtu(newConnectedDevices))
            .then((_) {
          developer.log("Notifying listeners...", name: TAG);
          notifyListeners();
        });
      }
    });
  }

  /// Notifies flutter blue of a disconnection.
  ///
  /// When a device gets disconnected from the application, it's important to
  /// make the disconnection explicit with Flutter Blue, otherwise we might
  /// stumble with a Platform exception when the device gets reconnected.
  ///
  /// In order to reconnect a device, the user will have to manually go to the
  /// connections page and reconnect the device (as opposed to automatic
  /// reconnection).
  void _assertAnyDisconnection(List<BluetoothDevice> oldDevices,
      List<BluetoothDevice> newDevices) async {
    if (oldDevices.length > newDevices.length) {
      Set<BluetoothDevice> disconnectedDevices =
          oldDevices.toSet().difference(newDevices.toSet());
      for (var disconnectedDevice in disconnectedDevices) {
        await disconnectedDevice.disconnect();
      }
    }
  }

  /// Reloads the information of the characteristics contained in the class.
  Future _updateState(List<BluetoothDevice> connectedDevices) async {
    try {
      Map<BluetoothDevice, BluetoothService> devicesServices =
      await getDevicesLsaGlovesServices(connectedDevices);
      developer.log("Retrieved device services amount: ${devicesServices.length}.", name: TAG);
      this._controllerCharacteristics =
          getDevicesControllerCharacteristics(devicesServices);
      this._dataCollectionCharacteristics =
          getDevicesDataCollectionCharacteristics(devicesServices);
      this._interpretationCharacteristics =
          getDevicesInterpretationCharacteristics(devicesServices);
    } catch (err) {
      developer.log("Error retrieving services: ${err.toString()}.", name: TAG);
    }
  }

  /// Requests a MTU update with [BluetoothSpecification.MTU_BYTES_SIZE] to the
  /// [connectedDevices].
  Future _requestMtu(List<BluetoothDevice> connectedDevices) async {
    try {
      for (var device in connectedDevices) {
        device.requestMtu(BluetoothSpecification.MTU_BYTES_SIZE);
      }
    } catch (err) {
      developer.log("Error requesting MTU: ${err.toString()}", name: TAG);
    }
  }

  /// Retrieves the connected devices.
  static Future<List<BluetoothDevice>> getConnectedDevices() {
    return FlutterBlue.instance.connectedDevices;
  }

  static void sendStartDataCollectionCommand(
      List<BluetoothDevice> connectedDevices) async {
    sendCommandToConnectedDevices(
        connectedDevices, BluetoothSpecification.START_DATA_COLLECTION);
  }

  static void sendStartInterpretationCommand(
      List<BluetoothDevice> connectedDevices) async {
    sendCommandToConnectedDevices(
        connectedDevices, BluetoothSpecification.START_INTERPRETATIONS);
  }

  /// Sends the interpretation command through the specified controller
  /// characteristics passed as parameters.
  static void sendStartInterpretationCommandToControllers(
      Iterable<BluetoothCharacteristic> controllerCharacteristics) {
    for (var characteristic in controllerCharacteristics) {
      writeCommandToCharacteristic(
          BluetoothSpecification.START_INTERPRETATIONS, characteristic);
    }
  }

  /// Sends the stop command through the specified controller characteristics
  /// passed as parameters.
  static void sendStopCommandToControllers(
      Iterable<BluetoothCharacteristic> controllerCharacteristics) {
    for (var characteristic in controllerCharacteristics) {
      writeCommandToCharacteristic(
          BluetoothSpecification.STOP_ONGOING_TASK, characteristic);
    }
  }

  static void sendCalibrationCommand(BluetoothDevice device) async {
    sendCommandToConnectedDevice(device, BluetoothSpecification.CALIBRATE);
  }

  static Future sendStopCommand(List<BluetoothDevice> connectedDevices) async {
    await sendCommandToConnectedDevices(
        connectedDevices, BluetoothSpecification.STOP_ONGOING_TASK);
  }

  /// Sends the command specified as a parameter to the connected device
  /// through the control characteristic.
  static void sendCommandToConnectedDevice(
      BluetoothDevice connectedDevice, String command) async {
    BluetoothService? service = await getLsaGlovesService(connectedDevice);
    if (service != null) {
      BluetoothCharacteristic characteristic =
          getControllerCharacteristic(service);
      writeCommandToCharacteristic(command, characteristic);
    }
  }

  static void writeCommandToCharacteristic(
      String command, BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.write(utf8.encode(command), withoutResponse: true);
    } catch (err) {
      developer.log("Characteristic write failed: " + err.toString(),
          name: TAG);
    }
  }

  /// Sends the commands specified as a parameter to the connected devices
  /// through the control characteristic.
  ///
  /// This method is expected to be used to start and stop the measurement
  /// readings from the glove as well as the interpretations.
  static Future sendCommandToConnectedDevices(
      List<BluetoothDevice> connectedDevices, String command) async {
    Map<BluetoothDevice, BluetoothService> services =
        await getDevicesLsaGlovesServices(connectedDevices);
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics =
        getDevicesControllerCharacteristics(services);
    characteristics.values.forEach((characteristic) async {
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
    try {
      List<BluetoothService> services =
          await bluetoothDevice.discoverServices();
      return services.firstWhereOrNull((service) {
        developer.log("Service uuid: ${service.uuid.toString()}", name: TAG);
        return service.uuid.toString() ==
            BluetoothSpecification.LSA_GLOVE_SERVICE_UUID;
      });
    } catch (error) {
      developer.log(
          "Failed retrieving services for device ${bluetoothDevice.id.id}: " +
              error.toString(),
          name: TAG);
      return Future.error(error);
    }
  }

  static Future<Map<BluetoothDevice, BluetoothService>>
      getDevicesLsaGlovesServices(List<BluetoothDevice> devices) async {
    Map<BluetoothDevice, BluetoothService> services = Map();
    for (var device in devices) {
      BluetoothService? service = await getLsaGlovesService(device);
      if (service != null) {
        services[device] = service;
      }
    }
    return services;
  }

  static Map<BluetoothDevice, BluetoothCharacteristic>
      getDevicesDataCollectionCharacteristics(
          Map<BluetoothDevice, BluetoothService> connectedDevicesServices) {
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics = Map();
    for (MapEntry<BluetoothDevice, BluetoothService> entry
        in connectedDevicesServices.entries) {
      characteristics[entry.key] = getDataCollectionCharacteristic(entry.value);
    }
    return characteristics;
  }

  static Map<BluetoothDevice, BluetoothCharacteristic>
      getDevicesControllerCharacteristics(
          Map<BluetoothDevice, BluetoothService> connectedDevicesServices) {
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics = Map();
    for (MapEntry<BluetoothDevice, BluetoothService> entry
        in connectedDevicesServices.entries) {
      characteristics[entry.key] = getControllerCharacteristic(entry.value);
    }
    return characteristics;
  }

  static Map<BluetoothDevice, BluetoothCharacteristic>
      getDevicesInterpretationCharacteristics(
          Map<BluetoothDevice, BluetoothService> connectedDevicesServices) {
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics = Map();
    for (MapEntry<BluetoothDevice, BluetoothService> entry
        in connectedDevicesServices.entries) {
      characteristics[entry.key] = getInterpretationCharacteristic(entry.value);
    }
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

  /// Retrieves the interpretation characteristic from the {@code bluetoothService}
  /// specified.
  static BluetoothCharacteristic getInterpretationCharacteristic(
      BluetoothService bluetoothService) {
    return bluetoothService.characteristics.firstWhere((characteristic) =>
        characteristic.uuid.toString() ==
        BluetoothSpecification.INTERPRETATION_CHARACTERISTIC_UUID);
  }

  /// Retrieve the deviceName in spanish
  static String getSpanishGloveName(String deviceName) {
    switch (deviceName) {
      case (BluetoothSpecification.RIGHT_GLOVE_NAME):
        return RightGlove;
      case (BluetoothSpecification.LEFT_GLOVE_NAME):
        return LeftGlove;
      default:
        return deviceName;
    }
  }

  static Future<void> requestMtu(List<BluetoothDevice> connectedDevices) async {
    for (var device in connectedDevices) {
      await device.requestMtu(BluetoothSpecification.MTU_BYTES_SIZE);
    }
  }
}
