import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/pages/ble_data_collection_page.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/movement.dart';
import 'package:lsa_gloves/widgets/Dialog.dart';

class ServiceTile extends StatelessWidget {
  final String deviceId;
  final BluetoothService service;
  final List<BluetoothCharacteristic> characteristics;

  const ServiceTile(
      {Key? key,
      required this.deviceId,
      required this.service,
      required this.characteristics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristics.length < 1) {
      return ListTile(
        title: Text('Error en el servicio ${service.uuid.toString()}'),
        subtitle: Text('caracteristica no encontrada'),
        onTap: () => null,
      );
    } else {
      return Column(
        children: [
          Container(
              width: double.infinity,
              child: Card(
                  child: TextButton(
                child: const Text('Calibrar'),
                onPressed: null,
              ))),
          Container(
              width: double.infinity,
              child: Card(
                child: TextButton(
                    child: const Text('Recolectar datos'),
                    onPressed: () {
                      print(service.uuid);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BleDataCollectionPage(
                              deviceId: deviceId,
                              characteristic: characteristics.first),
                          maintainState: false));
                    }),
              ))
        ],
      );
    }
  }
}

/// This is the stateful widget of my characteristic.
class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;
  final String deviceId;

  CharacteristicTile(
      {Key? key, required this.deviceId, required this.characteristic})
      : super(key: key);

  @override
  State<CharacteristicTile> createState() =>
      _BLEMovementRecorderWidget(this.deviceId, this.characteristic, false);
}

/// This is the private State class of the data collection widget.
class _BLEMovementRecorderWidget extends State<CharacteristicTile> {
  bool _isRecording;
  final BluetoothCharacteristic characteristic;
  final String deviceId;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  StreamController<Movement> _streamController;
  List<Movement> _items;

  _BLEMovementRecorderWidget(
      this.deviceId, this.characteristic, this._isRecording)
      : _streamController = new StreamController.broadcast(),
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
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                  onPressed: () => null,
                ),
                _getRecordingButton(),
              ],
            ));
      },
    );
  }

  Widget _getRecordingButton() {
    if (_isRecording) {
      return IconButton(
        icon: Icon(Icons.stop, color: Colors.red),
        onPressed: () => stopRecording(),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.circle, color: Theme.of(context).primaryColor),
        onPressed: () => startRecording(),
      );
    }
  }

  Future<VoidCallback?> startRecording() async {
    print('startRecording');
    setState(() {
      _isRecording = true;
    });
    print('streamController');
    _streamController = new StreamController.broadcast();
    _streamController.stream.listen((p) => {setState(() => _items.add(p))});
    print('load msg from connection into item list');
    await characteristic.setNotifyValue(true);
    await characteristic.read();
  }

  Future<VoidCallback?> stopRecording() async {
    print('stopRecording');
    _streamController.close();
    setState(() {
      _isRecording = false;
    });
    if (_items.isNotEmpty) {
      saveMessagesInFile("PALABRA", this._items);
    }
    await characteristic.setNotifyValue(false);
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
