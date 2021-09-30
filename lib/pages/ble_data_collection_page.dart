import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/pages/ble_connection_error_page.dart';
import 'package:lsa_gloves/widgets/Dialog.dart';
import 'package:simple_timer/simple_timer.dart';
import 'dart:developer' as developer;

class BleDataCollectionPage extends StatefulWidget {
  const BleDataCollectionPage({Key? key}) : super(key: key);

  @override
  _BleDataCollectionState createState() => _BleDataCollectionState(false);
}

class _BleDataCollectionState extends State<BleDataCollectionPage>
    with SingleTickerProviderStateMixin {
  static const String TAG = "BleDataCollection";
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  bool _isRecording;
  late TimerController _timerController;
  late MeasurementsPanel rightDataWidget;
  late MeasurementsPanel leftDataWidget;

  _BleDataCollectionState(this._isRecording) {
    this._timerController = TimerController(this);
    this.rightDataWidget = MeasurementsPanel(
        deviceName: BluetoothSpecification.RIGHT_GLOVE_NAME,
        key: ValueKey<Object>(Object()));
    this.leftDataWidget = MeasurementsPanel(
        deviceName: BluetoothSpecification.LEFT_GLOVE_NAME,
        key: ValueKey<Object>(Object()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              child: Text(
                "Categoría",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 4),
            buildDropdownButton(categories, selectedCategory,
                (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
                gestures = getGestureList(selectedCategory);
                selectedGesture = gestures[0];
              });
            }),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: Text(
                "Gesto",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 4),
            buildDropdownButton(gestures, selectedGesture, (String? newValue) {
              setState(() {
                this.selectedGesture = newValue!;
              });
            }),
            SizedBox(height: 4),
            Expanded(
                child: Column(
              children: <Widget>[this.rightDataWidget, this.leftDataWidget],
            )),
            Container(
              width: 200,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SimpleTimer(
                    controller: _timerController,
                    duration: Duration(seconds: 10),
                    progressIndicatorColor: Theme.of(context).primaryColor,
                    progressTextStyle: TextStyle(color: Colors.transparent),
                    strokeWidth: 15,
                  ),
                  Padding(
                      padding: EdgeInsets.all(24),
                      child: buildRecordingButton()),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
        // }),
      )),
    );
  }

  DropdownButton<String> buildDropdownButton(List<String> values,
      String selectedValue, Function(String?)? onSelected) {
    return DropdownButton(
        isExpanded: true,
        value: selectedValue,
        onChanged: onSelected,
        items: values.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList());
  }

  Container buildRecordingButton() {
    return Container(
        width: 150.0,
        height: 150.0,
        child: (() {
          if (_isRecording) {
            return IconButton(
              icon: Icon(Icons.stop, color: Colors.red, size: 64),
              onPressed: () => stopRecording(),
            );
          } else {
            return IconButton(
              icon: Icon(Icons.circle,
                  color: Theme.of(context).primaryColor, size: 64),
              onPressed: () => startRecording(),
            );
          }
        })());
  }

  Future<VoidCallback?> startRecording() async {
    developer.log('startRecording', name: TAG);
    List<BluetoothDevice> connectedDevices =
        await BluetoothBackend.getConnectedDevices();
    if (connectedDevices.isEmpty) {
      developer.log('Cant start recording! No device connected', name: TAG);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BleConnectionErrorPage(),
          maintainState: false));
    } else {
      BluetoothBackend.sendStartDataCollectionCommand(connectedDevices);
      this._timerController.start();
      setState(() {
        _isRecording = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Capturando movimientos..."),
          duration: Duration(seconds: 2)));
    }
  }

  Future<VoidCallback?> stopRecording() async {
    developer.log('stopRecording', name: TAG);
    List<BluetoothDevice> connectedDevices =
        await BluetoothBackend.getConnectedDevices();
    await BluetoothBackend.sendStopCommand(connectedDevices);
    var rightGloveMeasurements =
        await this.rightDataWidget.stopRecordingMeasurements();
    var leftGloveMeasurements =
        await this.leftDataWidget.stopRecordingMeasurements();

    _timerController.reset();
    setState(() {
      this._isRecording = false;
      this.rightDataWidget = MeasurementsPanel(
          deviceName: BluetoothSpecification.RIGHT_GLOVE_NAME,
          key: ValueKey<Object>(Object()));
      this.leftDataWidget = MeasurementsPanel(
          deviceName: BluetoothSpecification.LEFT_GLOVE_NAME,
          key: ValueKey<Object>(Object()));
    });

    String gesture = "$selectedCategory-$selectedGesture";
    await saveMessagesInFile(context, gesture, rightGloveMeasurements);
    //TODO save left hand measurements!
    //await saveMessagesInFile(context, gesture, leftGloveMeasurements);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Movimientos guardados!"),
        duration: Duration(seconds: 1)));
  }

  Future saveMessagesInFile(BuildContext context, String selectedGesture,
      List<GloveMeasurement> gloveMeasurements) async {
    if (gloveMeasurements.isEmpty) {
      developer.log("Empty measurements list, nothing to save", name: TAG);
      return;
    }
    //open pop up loading
    Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
    var deviceId = gloveMeasurements.first.deviceId;
    var measurementFile =
        await DeviceMeasurementsFile.create(deviceId, selectedGesture);
    for (int i = 0; i < gloveMeasurements.length; i++) {
      measurementFile.add(gloveMeasurements[i]);
    }
    await measurementFile.save();
    //close pop up loading
    Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop();
  }

  static List<String> getCategoryList() {
    return <String>["Números", "Letras", "Saludo"];
  }

  static List<String> getGestureList(String category) {
    if (category == "Números") {
      return <String>["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    }
    if (category == "Letras") {
      return <String>["a", "b", "c"];
    }
    if (category == "Saludo") {
      return <String>["Hola", "¿Cómo estás?", "Adiós"];
    }
    return [];
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}

/// Widget to display the dataCollection of each glove.
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
                color:Theme.of(context).primaryColor ));
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
