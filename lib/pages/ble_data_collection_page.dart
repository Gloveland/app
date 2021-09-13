
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/movement.dart';
import 'package:lsa_gloves/widgets/Dialog.dart';
import 'package:simple_timer/simple_timer.dart';


class BleDataCollectionPage extends StatefulWidget {
  String deviceId;
  BluetoothCharacteristic characteristic;
  BleDataCollectionPage({Key? key, required this.deviceId, required this.characteristic}) : super(key: key);

  @override
  _BleDataCollectionState createState() => _BleDataCollectionState(this.deviceId, this.characteristic, false);
}

class _BleDataCollectionState extends State<BleDataCollectionPage> with SingleTickerProviderStateMixin{
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];

  bool _isRecording;
  final String deviceId;
  final BluetoothCharacteristic characteristic;
  late TimerController _timerController;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  StreamController<Movement> _streamController;
  List<Movement> _items;


  _BleDataCollectionState(this.deviceId, this.characteristic, this._isRecording)
      : _streamController = new StreamController.broadcast(),
        _items = [] {
    _streamController = new StreamController.broadcast();
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
        child: StreamBuilder<List<int>>(
            stream: characteristic.value,
            initialData: characteristic.lastValue,
            builder: (c, snapshot) {
              final value = snapshot.data;
              readGloveMeasurementsFromBle(value!);
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
              icon: Icon(
                  Icons.stop,
                  color: Colors.red,
                  size: 64),
              onPressed: () => stopRecording(),
            );
          } else {
            return IconButton(
              icon: Icon(Icons.circle,
                  color: Theme.of(context).primaryColor,
                  size: 64),
              onPressed: () => startRecording(),
            );
        }
        })());
  }

  Future<VoidCallback?> startRecording() async {
    print('startRecording');
    _timerController.start();
    setState(() {
      _isRecording = true;
    });
    print('streamController');
    _streamController = new StreamController.broadcast();
    _streamController.stream.listen((p) => {setState(() => _items.add(p))});
    print('load msg from connection into item list');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Capturando movimientos..."),
        duration: Duration(seconds: 2)));
    await characteristic.setNotifyValue(true);
    await characteristic.read();

  }

  Future<VoidCallback?> stopRecording() async {
    print('stopRecording');
    _timerController.reset();
    _streamController.close();
    setState(() {
      _isRecording = false;
    });
    if (_items.isNotEmpty) {
      saveMessagesInFile("$selectedCategory-$selectedGesture", this._items);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Movimientos guardados!"),
          duration: Duration(seconds: 1)));
    }
    await characteristic.setNotifyValue(false);
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


  readGloveMeasurementsFromBle(List<int> valueRead) {
    String stringRead = new String.fromCharCodes(valueRead);
    print("READING.... $stringRead");
    if (stringRead.isEmpty) {
      return;
    }
    if (this._streamController.isClosed) {
      print("skip: stream controller is close");
      return;
    }
    var lastCharacter = stringRead.substring(stringRead.length - 1);
    List<String> fingerMeasurements = stringRead
        .substring(0, stringRead.length - 1)
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
    if (fingerMeasurements.length < 6 || lastCharacter != ";") {
      print("last character is not the expected delimiter ';'"
          "have you change the MTU correctly ");
      return;
    }
    var eventNum = int.parse(fingerMeasurements.removeAt(0));
    try {
      print('trying to parse');
      var pkg = Movement.fromFingerMeasurementsList(
          eventNum, this.deviceId, fingerMeasurements);
      print('map to -> ${pkg.toJson().toString()}');
      this._streamController.add(pkg);
    } catch (e) {
      print('cant parse : $stringRead  error : ${e.toString()}');
    }
  }

  saveMessagesInFile(String word, List<Movement> movements) async {
    if (movements.isEmpty) {
      return;
    }
    //open pop up loading
    Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
    var deviceId = movements.first.deviceId;
    var measurementFile = await DeviceMeasurementsFile.create(deviceId, word);
    for (int i = 0; i < movements.length; i++) {
      print('saving in file -> ${movements[i].toJson().toString()}');
      measurementFile.add(movements[i]);
    }
    await measurementFile.save();
    this._items = [];
    //close pop up loading
    Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    _streamController.close();
  }
}
