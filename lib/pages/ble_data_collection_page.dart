import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:lsa_gloves/pages/ble_connection_error_page.dart';
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
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  bool _isRecording;
  late TimerController _timerController;
  late DataCollectionWidget rightDataWidget;
  late DataCollectionWidget leftDataWidget;

  _BleDataCollectionState(this._isRecording) {
    _timerController = TimerController(this);
    this.rightDataWidget = DataCollectionWidget(
        deviceName: BluetoothSpecification.RIGHT_GLOVE_NAME);
    this.leftDataWidget = DataCollectionWidget(
    deviceName: BluetoothSpecification.LEFT_GLOVE_NAME);
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
              children: <Widget>[
                this.rightDataWidget,
                this.leftDataWidget],
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
    }
  }

  Future<VoidCallback?> stopRecording() async {
    developer.log('stopRecording', name: TAG);
    _timerController.reset();
    setState(() {
      _isRecording = false;
    });
    List<BluetoothDevice> connectedDevices =
        await BluetoothBackend.getConnectedDevices();
    BluetoothBackend.sendStopCommand(connectedDevices);
    this.rightDataWidget.reset();
    this.leftDataWidget.reset();
    /*
    if (this._measurementsCollector != null) {
      String gesture = "$selectedCategory-$selectedGesture";
      await this._measurementsCollector!.stopReadings(context, gesture);
    }
     */
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
class DataCollectionWidget extends StatefulWidget {
  final String deviceName;

  const DataCollectionWidget({Key? key, required this.deviceName})
      : super(key: key);

  @override
  _DataCollectionWidgetState createState() =>
      _DataCollectionWidgetState(deviceName);

  void reset() {
    createState();
  }
}

class _DataCollectionWidgetState extends State<DataCollectionWidget> {
  static const String TAG = "DataCollectionWidget";
  final String deviceName;
  late Future characteristic;

  _DataCollectionWidgetState(this.deviceName);

  @override
  void initState() {
    super.initState();
    characteristic = _getFutureCharacteristic();
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
    return FutureBuilder(
        future: characteristic,
        builder: (c, characteristicSnapshot) {
          String stringRead = "";
          Widget dataWidget = Container();
          if (characteristicSnapshot.hasData) {
            BluetoothCharacteristic characteristic =
                characteristicSnapshot.data! as BluetoothCharacteristic;
            characteristic.setNotifyValue(true);
            characteristic.value.listen((data) {
              stringRead = new String.fromCharCodes(data);
              developer.log("Incoming data: [$stringRead]", name: TAG);
            }, onError: (err) {
              developer.log("Error: [${err.toString()}]", name: TAG);
            }, onDone: () {
              developer.log("Reading measurements done", name: TAG);
            });

            dataWidget = Container(
                width: double.infinity,
                alignment: Alignment.topCenter,
                decoration: new BoxDecoration(color: Colors.amberAccent),
                child: Text(stringRead, style: TextStyle(fontSize: 10)));
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
                        Expanded(child: dataWidget),
                        Container(
                            padding: EdgeInsets.all(5),
                            child: Text(BluetoothBackend.getSpanishGloveName(
                                this.deviceName)))
                      ]),
                    ),
                  )));
        });
  }

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + this.deviceName, name: TAG);
  }
}
