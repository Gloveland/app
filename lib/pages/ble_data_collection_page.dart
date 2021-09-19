import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
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
  List<BluetoothDevice> _connectedDevices;
  MeasurementsCollector? _measurementsCollector;

  _BleDataCollectionState(this._isRecording) : _connectedDevices = [] {
    _timerController = TimerController(this);
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
        child: StreamBuilder<List<BluetoothDevice>>(
            stream: Stream.periodic(Duration(seconds: 2))
                .asyncMap((_) => BluetoothBackend.getConnectedDevices()),
            initialData: [],
            builder: (context, devicesSnapshot) {
              if (devicesSnapshot.hasData) {
                this._connectedDevices = devicesSnapshot.data!;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    child: Text(
                      "Categoría",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 8),
                  buildDropdownButton(categories, selectedCategory,
                      (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                      gestures = getGestureList(selectedCategory);
                      selectedGesture = gestures[0];
                    });
                  }),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: Text(
                      "Gesto",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 8),
                  buildDropdownButton(gestures, selectedGesture,
                      (String? newValue) {
                    setState(() {
                      this.selectedGesture = newValue!;
                    });
                  }),
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        "Clickear el boton para comenzar a grabar los movimientos",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 74),
                  Container(
                    width: 200,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        SimpleTimer(
                          controller: _timerController,
                          duration: Duration(seconds: 10),
                          progressIndicatorColor:
                              Theme.of(context).primaryColor,
                          progressTextStyle:
                              TextStyle(color: Colors.transparent),
                          strokeWidth: 15,
                        ),
                        Padding(
                            padding: EdgeInsets.all(24),
                            child: buildRecordingButton()),
                      ],
                    ),
                  ),
                ],
              );
            }),
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
    if (this._connectedDevices.isEmpty) {
      developer.log('Cant start recording! No device connected', name: TAG);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BleConnectionErrorPage(),
          maintainState: false));
    } else {
      BluetoothBackend.sendStartDataCollectionCommand(this._connectedDevices);
      var dataCollectionCharacteristics =
          await BluetoothBackend.getDevicesDataCollectionCharacteristics(
              this._connectedDevices);
      String deviceId = "${this._connectedDevices.first.id}";
      this._measurementsCollector = new MeasurementsCollector(
          deviceId, dataCollectionCharacteristics.first);
      this._timerController.start();
      this._measurementsCollector!.readMeasurements(context);
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
    BluetoothBackend.sendStopCommand(this._connectedDevices);
    if (this._measurementsCollector != null) {
      String gesture = "$selectedCategory-$selectedGesture";
      await this._measurementsCollector!.stopReadings(context, gesture);
    }
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
