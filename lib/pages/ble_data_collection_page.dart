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
  _BleDataCollectionState createState() => _BleDataCollectionState();
}

class _BleDataCollectionState extends State<BleDataCollectionPage> {
  static const String TAG = "BleDataCollection";
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  MeasurementsCollector _measurementsCollector = MeasurementsCollector();
  List<BluetoothDevice>? _connectedDevices;
  bool _isRecording = false;
  
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
              this._connectedDevices = devicesSnapshot.data;
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
                  RecordButton(
                      key: Key("${devicesSnapshot.data!.length}"),
                      onButtonPressed: () => onRecordButtonPressed(),
                      devicesSnapshot: devicesSnapshot)
                ],
              );
            }),
      )),
    );
  }
  
  void onRecordButtonPressed() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    developer.log('startRecording');
    if (this._connectedDevices!.isEmpty) {
      developer.log('Cant start recording! No device connected');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BleConnectionErrorPage(),
          maintainState: false));
    } else {
      BluetoothBackend.sendStartDataCollectionCommand(_connectedDevices!);
      _measurementsCollector.startCollecting(this._connectedDevices!, this.selectedGesture);
      _isRecording = true;
      // TODO(https://git.io/JEyV4): Process data from more than one device.
    }
  }

  void _stopRecording() async {
    developer.log('stopRecording');
    BluetoothBackend.sendStopCommand(this._connectedDevices!);
    _isRecording = false;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text("Finalizar recolección."),
          content: Text(
              "¿Desea guardar los archivos o descartarlos?"),
          actions: [
            TextButton(
                onPressed: () {
                  _measurementsCollector.discardCollection();
                  Navigator.pop(context, 'Cancelar');
                },
                child: Text("Descartar")),
            TextButton(
                onPressed: () {
                  _measurementsCollector.saveCollection();
                  Navigator.pop(context, 'Guardar');
                },
                child: Text("Guardar")),
          ],
        ));
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
}

class RecordButton extends StatefulWidget {

  final AsyncSnapshot<List<BluetoothDevice>> devicesSnapshot;
  final Function onButtonPressed;

  const RecordButton({Key? key, required this.devicesSnapshot, required this.onButtonPressed}) : super(key: key);

  @override
  _RecordButtonState createState() => _RecordButtonState(devicesSnapshot, onButtonPressed);
}

class _RecordButtonState extends State<RecordButton> with SingleTickerProviderStateMixin {
  final AsyncSnapshot<List<BluetoothDevice>> devicesSnapshot;
  late List<BluetoothDevice> connectedDevices;
  late TimerController _timerController;
  bool _isRecording = false;
  Function onButtonPressed;

  _RecordButtonState(this.devicesSnapshot, this.onButtonPressed) {
    _timerController = new TimerController(this);
  }

  @override
  void initState() {
    super.initState();
    if (devicesSnapshot.hasData) {
      connectedDevices = devicesSnapshot.data!;
    }
    developer.log("Widget updated. Devices: " + connectedDevices.toString(), name: "RecordButton");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }

  Container buildRecordingButton() {
    return Container(
        width: 150.0,
        height: 150.0,
        child: (() {
          if (_isRecording) {
            return IconButton(
              icon: Icon(Icons.stop, color: Colors.red, size: 64),
              onPressed: () {
                onButtonPressed.call();
                _timerController.reset();
                setState(() {
                  _isRecording = false;
                });
              },
            );
          } else {
            return IconButton(
              icon: Icon(Icons.circle,
                  color: Theme.of(context).primaryColor, size: 64),
              onPressed: () {
                onButtonPressed.call();
                _timerController.start();
                setState(() {
                  _isRecording = true;
                });
              },
            );
          }
        })());
  }
}
