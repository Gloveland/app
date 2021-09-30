import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'dart:developer' as developer;

/// Widget to display the data that is being collected from a glove at real time.
class MeasurementsPanel extends StatefulWidget {
  final String deviceName;
  late final _MeasurementsPanelState measurementPanelState;

  MeasurementsPanel({Key? key, required this.deviceName}) : super(key: key) {
    this.measurementPanelState = _MeasurementsPanelState(this.deviceName);
  }

  @override
  _MeasurementsPanelState createState() => this.measurementPanelState;

  Future<List<GloveMeasurement>> stopRecordingMeasurements() async {
    return this.measurementPanelState.stopRecordingMeasurements();
  }
}

class _MeasurementsPanelState extends State<MeasurementsPanel> {
  static const String TAG = "MeasurementsPanel";
  final String deviceName;
  late Future characteristic;
  MeasurementsCollector? measurementsCollector;

  _MeasurementsPanelState(this.deviceName);

  @override
  void initState() {
    super.initState();
    this.characteristic = _getFutureCharacteristic();
  }

  @override
  void didUpdateWidget(MeasurementsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    developer.log("Updating MeasurementsPanel", name: TAG);
  }

  _getFutureCharacteristic() async {
    return BluetoothBackend.getConnectedDevices()
        .then((connectedDevices) => connectedDevices
            .firstWhere((device) => device.name == this.deviceName))
        .then((glove) => BluetoothBackend.getLsaGlovesService(glove))
        .then((service) =>
            BluetoothBackend.getDataCollectionCharacteristic(service!));
  }

  @override
  Widget build(BuildContext context) {
    developer.log("Building", name: TAG);
    return FutureBuilder(
        future: characteristic,
        builder: (c, characteristicSnapshot) {
          Widget dataCollectedWidget = Text("");
          if (characteristicSnapshot.hasData) {
            BluetoothCharacteristic c =
                characteristicSnapshot.data! as BluetoothCharacteristic;
            this.measurementsCollector =
                MeasurementsCollector(characteristic: c);
            dataCollectedWidget = this.measurementsCollector!;
          }
          return Expanded(
              child: Container(
                  width: double.infinity,
                  child: Card(
                    elevation: 5,
                    color: characteristicSnapshot.hasData
                        ? Theme.of(context).cardColor
                        : Theme.of(context).disabledColor,
                    child: ClipRRect(
                      child: Column(children: <Widget>[
                        Expanded(
                            child: Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: dataCollectedWidget)),
                        Container(
                            padding: EdgeInsets.all(5),
                            child: Text(BluetoothBackend.getSpanishGloveName(
                                this.deviceName)))
                      ]),
                    ),
                  )));
        });
  }

  Future<List<GloveMeasurement>> stopRecordingMeasurements() async {
    if (this.measurementsCollector == null) {
      developer.log("Not collecting data from " + deviceName, name: TAG);
      return [];
    }
    return this.measurementsCollector!.stopRecordingMeasurements();
  }

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + this.deviceName, name: TAG);
  }
}

/// Widget that listen to a characteristic and display the data that is being read.
/// It is also responsible for accumulate all the measurements
/// When the characteristic is not listened any more it returns a list of all measurements read
class MeasurementsCollector extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  late final _MeasurementsCollector measurementCollectorState;

  MeasurementsCollector({Key? key, required this.characteristic})
      : super(key: key) {
    this.measurementCollectorState =
        _MeasurementsCollector(this.characteristic);
  }

  @override
  State<MeasurementsCollector> createState() => this.measurementCollectorState;

  Future<List<GloveMeasurement>> stopRecordingMeasurements() async {
    return this.measurementCollectorState.stopRecordingMeasurements();
  }
}

class _MeasurementsCollector extends State<MeasurementsCollector> {
  static const String TAG = "MeasurementsCollector";
  BluetoothCharacteristic characteristic;
  List<GloveMeasurement> _items;
  late StreamSubscription<List<int>> _subscription;

  _MeasurementsCollector(this.characteristic) : _items = [] {
    try {
      this.characteristic.setNotifyValue(true);
    } catch (err) {
      developer.log("Characteristic set Notify failed: " + err.toString(),
          name: TAG);
    }
    _subscription = this.characteristic.value.listen((data) {
      String stringRead = new String.fromCharCodes(data);
      developer.log("Incoming data: $stringRead", name: TAG);
      readGloveMeasurementsFromBle(stringRead);
    }, onError: (err) {
      developer.log("Error: ${err.toString()}", name: TAG);
    }, onDone: () {
      developer.log("Reading measurements done", name: TAG);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: gloveMeasurementStream(),
      initialData: "",
      builder: (c, snapshot) {
        return Text(snapshot.data!,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor));
      },
    );
  }

  Stream<String> gloveMeasurementStream() async* {
    for (var item in this._items) {
      var acc = item.middle.acc;
      var gyro = item.middle.gyro;
      yield "${acc.x}      ${acc.y}      ${acc.z}\n "
          "${gyro.x}      ${gyro.y}      ${gyro.z}";
    }
  }

  void readGloveMeasurementsFromBle(String stringRead) {
    if (stringRead.isEmpty) {
      return;
    }
    if (this._subscription.isPaused) {
      developer.log("skip: subscription is cancelled", name: TAG);
      return;
    }
    var lastCharacter = stringRead.substring(stringRead.length - 1);
    List<String> fingerMeasurements = stringRead
        .substring(0, stringRead.length - 1)
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
    if (fingerMeasurements.length < 6 || lastCharacter != ";") {
      developer.log(
          "last character is not the expected delimiter ';'"
          "have you change the MTU correctly ",
          name: TAG);
      return;
    }
    var eventNum = int.parse(fingerMeasurements.removeAt(0));
    try {
      developer.log('trying to parse');
      var pkg = GloveMeasurement.fromFingerMeasurementsList(
          eventNum, "deviceId", fingerMeasurements);
      developer.log('map to -> ${pkg.toJson().toString()}');
      setState(() => this._items.add(pkg));
    } catch (e) {
      developer.log('cant parse : $stringRead  error : ${e.toString()}');
    }
  }

  Future<List<GloveMeasurement>> stopRecordingMeasurements() async {
    try {
      await characteristic.setNotifyValue(false);
    } catch (err) {
      developer.log("Characteristic set Notify failed: " + err.toString(),
          name: TAG);
    }
    this._subscription.cancel();
    return this._items;
  }

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed MeasurementsCollector: ", name: TAG);
  }
}
