import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/movement.dart';

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;
  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('${service.uuid.toString()}',
                style: Theme.of(context).textTheme.body1?.copyWith(
                    color: Theme.of(context).textTheme.caption?.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle: Text('${service.uuid.toString()}'),
      );
    }
  }
}


/// This is the stateful widget that the main application instantiates.
class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final String deviceId;

  CharacteristicTile({Key? key, required this.deviceId, required this.characteristic})
      : super(key: key);

  @override
  State<CharacteristicTile> createState() =>
      _BLEMovementRecorderWidget(this.deviceId, this.characteristic, false);
}

/// This is the private State class that goes with MyStatefulWidget.
class _BLEMovementRecorderWidget extends State<CharacteristicTile> {
  bool _isRecording;
  final BluetoothCharacteristic characteristic;
  final String deviceId;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  StreamController<Movement> _streamController;
  List<Movement> _items;

  _BLEMovementRecorderWidget(this.deviceId, this.characteristic, this._isRecording) :
        _streamController = new StreamController.broadcast(),
        _items = [] {
    _streamController = new StreamController.broadcast();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        readGloveMeasurementsFromBle(value!);
        return ExpansionTile(
            title: ListTile(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Characteristic'),
                  Text('${characteristic.uuid.toString()}',
                      style: Theme.of(context).textTheme.body1?.copyWith(
                          color: Theme.of(context).textTheme.caption?.color))
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                      characteristic.isNotifying
                          ? Icons.sync_disabled
                          : Icons.sync,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                  onPressed: () async {
                    await characteristic.setNotifyValue(!characteristic.isNotifying);
                    await characteristic.read();
                  },
                )
              ],
            )
        );
      },
    );
  }


  /*

  VoidCallback? startRecording() {
    print('startRecording');
    setState(() {
      _isRecording = true;
    });
    print('streamController');
    _streamController = new StreamController.broadcast();
    _streamController.stream.listen((p) => {setState(() => _items.add(p))});
    print('load msg from connection into item list');
  }

  VoidCallback? stopRecording() {
    print('stopRecording');
    _streamController.close();
    setState(() {
      _isRecording = false;
    });
    if (_items.isNotEmpty) {
      saveMessagesInFile("PALABRA", this._items);
    }
  }
   */


  readGloveMeasurementsFromBle(List<int> valueRead) {
    String stringRead = new String.fromCharCodes(valueRead);
    print("READING.... $stringRead");
    if(stringRead.isEmpty){
      return;
    }
    if (this._streamController.isClosed) {
      print("skip: stream controller is close");
      return;
    }
    var lastCharacter = stringRead.substring(stringRead.length - 1);
    List<String> fingerMeasurements = stringRead.substring(0, stringRead.length - 1).split('\n').where((s) => s.isNotEmpty).toList();
    if(fingerMeasurements.length < 6 ||lastCharacter != ";"){
      print("last character is not the expected delimiter ';'"
          "have you change the MTU correctly ");
      return;
    }
    var eventNum = int.parse(fingerMeasurements.removeAt(0));
    try {
      print('trying to parse');
      var pkg = Movement.fromFingerMeasurementsList(eventNum, this.deviceId, fingerMeasurements);
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
    //Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
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
}
