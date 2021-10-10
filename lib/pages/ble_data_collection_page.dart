import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

class _BleDataCollectionState extends State<BleDataCollectionPage>
    with SingleTickerProviderStateMixin {
  static const String TAG = "BleDataCollection";
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  bool _isRecording = false;
  List<BluetoothDevice> _connectedDevices = [];
  MeasurementsCollector _measurementsCollector = MeasurementsCollector();

  Stream<List<BluetoothDevice>> connectedDevices() async* {
    Set<String> connectedDevicesIds = new Set();
    Stream<List<BluetoothDevice>> source = Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => BluetoothBackend.getConnectedDevices());
    await for (var devices in source) {
      Set<String> newConnectedDevicesIds =
          devices.map((device) => "${device.id.id}").toSet();
      if (!setEquals(newConnectedDevicesIds, connectedDevicesIds)) {
        developer.log(connectedDevicesIds.toString(), name: TAG);
        connectedDevicesIds = newConnectedDevicesIds;
        yield devices;
      }
    }
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
            stream: connectedDevices(),
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
                  SizedBox(height: 100),
                  RecordButton(
                      key: ValueKey(this._connectedDevices.length),
                      disabled: this._connectedDevices.isEmpty,
                      onButtonPressed: () => onRecordButtonPressed())
                ],
              );
            }),
      )),
    );
  }

  Future<void> onRecordButtonPressed() async {
    if (_isRecording) {
      _stopRecording();
    } else {
      await Future.wait([
        BluetoothBackend.requestMtu(this._connectedDevices)
            .then((value) => developer.log('Request mtu complete', name: TAG)),
        showDialog(
            context: context,
                builder: (context) {
                  return this._countDownDialogBuilder();
                })
            .then((value) =>
                developer.log("CountDown dialog complete", name: TAG))
      ]);
      _startRecording();
    }
  }

  Widget _countDownDialogBuilder() {
    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50.0))),
        content: Container(
            height: 200,
            width: 200,
            child: DefaultTextStyle(
                style: Theme.of(context).textTheme.headline2!,
                child: Center(
                    child: AnimatedTextKit(
                  isRepeatingAnimation: false,
                  animatedTexts: [
                    ScaleAnimatedText('3', scalingFactor: 0.1),
                    ScaleAnimatedText('2', scalingFactor: 0.1),
                    ScaleAnimatedText('1', scalingFactor: 0.1),
                    ScaleAnimatedText('ya!',
                        scalingFactor: 0,
                        duration: const Duration(milliseconds: 700)),
                  ],
                  onFinished: () => Navigator.pop(context),
                )))));
  }

  void _startRecording() {
    developer.log('startRecording');
    if (this._connectedDevices.isEmpty) {
      developer.log('Cant start recording! No device connected');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => BleConnectionErrorPage(),
          maintainState: false));
    } else {
      BluetoothBackend.sendStartDataCollectionCommand(_connectedDevices);
      _measurementsCollector.startCollecting(
          this._connectedDevices, this.selectedGesture);
      _isRecording = true;
    }
  }

  void _stopRecording() async {
    developer.log('stopRecording');
    BluetoothBackend.sendStopCommandToDevices(this._connectedDevices);
    _isRecording = false;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              title: Text("Finalizar recolección."),
              content: Text("¿Desea guardar los archivos o descartarlos?"),
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
  final Function onButtonPressed;
  final bool disabled;

  const RecordButton(
      {Key? key, required this.disabled, required this.onButtonPressed})
      : super(key: key);

  @override
  _RecordButtonState createState() =>
      _RecordButtonState(disabled, onButtonPressed);
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late TimerController _timerController;
  late bool _isRecording;
  bool _disabled;
  Function onButtonPressed;

  _RecordButtonState(this._disabled, this.onButtonPressed) {
    this._isRecording = false;
    this._timerController = new TimerController(this);
  }

  @override
  Widget build(BuildContext context) {
    developer.log("build _RecordButtonState");
    return Container(
      width: 200,
      height: 300,
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
          Padding(padding: EdgeInsets.all(24), child: buildRecordingButton()),
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
              onPressed: _disabled
                  ? null
                  : () async {
                      await onButtonPressed.call();
                      _timerController.reset();
                      setState(() {
                        _isRecording = false;
                      });
                    },
            );
          } else {
            return IconButton(
              icon: Icon(Icons.circle,
                  color: _disabled
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColor,
                  size: 64),
              onPressed: _disabled
                  ? null
                  : () async {
                      await onButtonPressed.call();
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
