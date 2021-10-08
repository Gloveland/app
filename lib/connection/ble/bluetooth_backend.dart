import 'dart:async';
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

  static final BluetoothBackend _bluetoothBackend =
      BluetoothBackend._internal();

  factory BluetoothBackend() {
    return _bluetoothBackend;
  }

  List<BluetoothDevice> connectedDevices = [];
  Map<BluetoothDevice, BluetoothCharacteristic> controllerCharacteristics =
      Map();
  Map<BluetoothDevice, BluetoothCharacteristic> dataCollectionCharacteristics =
      Map();
  Map<BluetoothDevice, BluetoothCharacteristic> interpretationCharacteristics =
      Map();

  late Stream<List<BluetoothDevice>> connectedDevicesStream;

  /// Stream controller for the streams providing the updated controller characteristics.
  var _controllerCharacteristicsSC =
      StreamController<Map<BluetoothDevice, BluetoothCharacteristic>>.broadcast();

  /// Stream controller for the streams providing the updated data collection characteristics.
  var _dataCollectionCharacteristicsSC =
      StreamController<Map<BluetoothDevice, BluetoothCharacteristic>>.broadcast();

  /// Stream controller for the streams providing the updated interpretation characteristics.
  var _interpretationCharacteristicsSC =
      StreamController<Map<BluetoothDevice, BluetoothCharacteristic>>.broadcast();
  
  Stream<Map<BluetoothDevice, BluetoothCharacteristic>> get dataCollectionCharacteristicsStream {
    return _dataCollectionCharacteristicsSC.stream;
  }

  Stream<Map<BluetoothDevice, BluetoothCharacteristic>> get interpretationCharacteristicsStream {
    return _interpretationCharacteristicsSC.stream;
  }

  Stream<Map<BluetoothDevice, BluetoothCharacteristic>> get controllerCharacteristicsStream {
    return _controllerCharacteristicsSC.stream;
  }

  BluetoothBackend._internal() {
    startMonitoringDevices();
  }

  void startMonitoringDevices() {
    this.connectedDevicesStream = Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => BluetoothBackend.getConnectedDevices()).asBroadcastStream();
    this.connectedDevicesStream
        .listen((connectedDevices) {
      if (this.connectedDevices.length != connectedDevices.length) {
        this.connectedDevices = connectedDevices;
        _requestMtu(connectedDevices);
        _updateState(connectedDevices);
        _notifyStreamListeners();
      }
    });
  }

  void _updateState(List<BluetoothDevice> connectedDevices) async {
    Map<BluetoothDevice, BluetoothService> devicesServices =
        await getDevicesLsaGlovesServices(connectedDevices);
    this.controllerCharacteristics =
        getDevicesControllerCharacteristics(devicesServices);
    this.dataCollectionCharacteristics =
        getDevicesDataCollectionCharacteristics(devicesServices);
    this.interpretationCharacteristics =
        getDevicesInterpretationCharacteristics(devicesServices);
  }

  void _notifyStreamListeners() {
    _controllerCharacteristicsSC.add(this.controllerCharacteristics);
    _dataCollectionCharacteristicsSC.add(this.dataCollectionCharacteristics);
    _interpretationCharacteristicsSC.add(this.interpretationCharacteristics);
  }

  void _requestMtu(List<BluetoothDevice> connectedDevices) {
    for (var device in connectedDevices) {
      device.requestMtu(BluetoothSpecification.MTU_BYTES_SIZE);
    }
  }

  void sendStartInterpretationCommandToConnectedDevices() {
    for (var characteristic in controllerCharacteristics.values) {
      writeCommandToCharacteristic(
          BluetoothSpecification.START_INTERPRETATIONS, characteristic);
    }
  }

  void sendStopCommandToConnectedDevices() {
    for (var characteristic in controllerCharacteristics.values) {
      writeCommandToCharacteristic(
          BluetoothSpecification.STOP_ONGOING_TASK, characteristic);
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
    characteristics.forEach((_, characteristic) async {
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
    for (MapEntry entry in connectedDevicesServices.entries) {
      characteristics[entry.key] = getDataCollectionCharacteristic(entry.value);
    }
    return characteristics;
  }

  static Map<BluetoothDevice, BluetoothCharacteristic>
      getDevicesControllerCharacteristics(
          Map<BluetoothDevice, BluetoothService> connectedDevicesServices) {
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics = Map();
    for (MapEntry entry in connectedDevicesServices.entries) {
      characteristics[entry.key] = getControllerCharacteristic(entry.value);
    }
    return characteristics;
  }

  static Map<BluetoothDevice, BluetoothCharacteristic>
      getDevicesInterpretationCharacteristics(
          Map<BluetoothDevice, BluetoothService> connectedDevicesServices) {
    Map<BluetoothDevice, BluetoothCharacteristic> characteristics = Map();
    for (MapEntry entry in connectedDevicesServices.entries) {
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
}
