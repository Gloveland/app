import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/datacollection/ble_data_collection_widgets.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
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
      drawer: NavDrawer(),
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

