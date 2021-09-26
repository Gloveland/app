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

  _BleDataCollectionState(this._isRecording) {
    _timerController = TimerController(this);
  }

  /*
  Future<void> loadDataCollectionStream() async {
    // TODO(https://git.io/JEyV4): Process data from more than one device.
    var connectedDevices = await BluetoothBackend.getConnectedDevices();
    var measurementsCollector =
        await BluetoothBackend.getLsaGlovesService(connectedDevices.first)
            .then((service) =>
                BluetoothBackend.getDataCollectionCharacteristic(service!))
            .then((characteristic) {
      String deviceId = "${connectedDevices.first.id}";
      return new MeasurementsCollector(deviceId, characteristic);
    });
    measurementsCollector.readMeasurements(context);
  }
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child:
            Column(
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
            buildDropdownButton(gestures, selectedGesture, (String? newValue) {
              setState(() {
                this.selectedGesture = newValue!;
              });
            }),
            SizedBox(height: 24),
            Container(
              width: 200,
              height: 300,
              decoration: new BoxDecoration(
                  color: Colors.green
              ),
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
            _dataCollectionWidgets(),
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

  _dataCollectionWidgets() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
    StreamBuilder(
    stream: Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => BluetoothBackend.getConnectedDevices()),
        builder:
            (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData) {
            return Loader();
          }
        Container(
          width: double.infinity,
          alignment: Alignment.topCenter,
          decoration: new BoxDecoration(
              color: Colors.amberAccent
          ),
          child: Text("3.4, 2.4", style: TextStyle(fontSize: 16)),
        )
      ],
    );
    /*return StreamBuilder<List<BluetoothDevice>>(
        stream: Stream.periodic(Duration(seconds: 2))
            .asyncMap((_) => BluetoothBackend.getConnectedDevices()),
        builder: (c, devicesSnapshot) {
          List<Widget> children = <Widget>[];
          if (devicesSnapshot.hasData) {
            developer.log('devices found', name: TAG);
            devicesSnapshot.data!.forEach((deviceElement) async {
              var characteristic =
                  await BluetoothBackend.getLsaGlovesService(deviceElement)
                      .then((service) =>
                          BluetoothBackend.getDataCollectionCharacteristic(
                              service!));
              var deviceId = "${deviceElement.id}";
              developer.log(deviceId, name: TAG);
              developer.log("${characteristic.uuid}", name: TAG);
              var measurementCollector = new MeasurementsCollector(
                  deviceId, characteristic);
              children.add(DataCollectionWidget(
                  //key: Key(deviceId),
                  device: deviceElement,
                  measurementsCollector: measurementCollector));
              children.add(SizedBox(height: 16));
            });
          }
          return Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );
        });

     */
  }

  Future<VoidCallback?> startRecording() async {
    developer.log('startRecording', name: TAG);
    List<BluetoothDevice> connectedDevices = await BluetoothBackend.getConnectedDevices();
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
  final BluetoothDevice device;
  final MeasurementsCollector measurementsCollector;

  const DataCollectionWidget(
      {Key? key, required this.device, required this.measurementsCollector})
      : super(key: key);

  @override
  _DataCollectionWidgetState createState() =>
      _DataCollectionWidgetState(device, measurementsCollector);
}

class _DataCollectionWidgetState extends State<DataCollectionWidget> {
  static const String TAG = "DataCollectionWidget";
  final BluetoothDevice device;
  final MeasurementsCollector measurementsCollector;

  _DataCollectionWidgetState(this.device, this.measurementsCollector);

  @override
  Widget build(BuildContext context) {
    return  Container(
        width: double.infinity,
        alignment: Alignment.topCenter,
      decoration: new BoxDecoration(
          color: Colors.amberAccent
      ),
        child: Text("3.4, 2.4", style: TextStyle(fontSize: 16)),
    );
  }

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + device.id.id, name: TAG);
  }
}
