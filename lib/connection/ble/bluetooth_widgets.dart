import 'dart:async';
import 'dart:convert';

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

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final String deviceId;
  late final List<DescriptorTile> descriptorTiles;

  StreamController<Movement> _streamController;
  List<Movement> _items;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();



  CharacteristicTile({Key? key, required this.deviceId, required this.characteristic}) :
        _streamController = new StreamController.broadcast(),
        _items = [],
        super(key: key){
    this.descriptorTiles = characteristic.descriptors.map(
          (descriptor) => DescriptorTile(
        descriptor: descriptor
      ),
    ).toList();
  }

  _readGloveMeasurements(List<int> valueRead) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
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
            subtitle: Text(_readGloveMeasurements(value!).toString()),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
                onPressed: () async {
                  await characteristic.read();
                },
              ),
              IconButton(
                icon: Icon(Icons.file_upload,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: () async {
                  await characteristic.write(
                      utf8.encode("on write characteristic"),
                      withoutResponse: true);
                  await characteristic.read();
                },
              ),
              IconButton(
                icon: Icon(
                    characteristic.isNotifying
                        ? Icons.sync_disabled
                        : Icons.sync,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: () async {
                  await characteristic
                      .setNotifyValue(!characteristic.isNotifying);
                  await characteristic.read();
                },
              )
            ],
          ),
          children: descriptorTiles,
        );
      },
    );
  }

  saveMessagesInFile(String fileName, List<Movement> movements) async {
    if (movements.isEmpty) {
      return;
    }
    //open pop up loading
   // Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
    var word = fileName;
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

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;

  const DescriptorTile(
      {Key? key,
      required this.descriptor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .body1
                  ?.copyWith(color: Theme.of(context).textTheme.caption?.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: () => descriptor.read(),
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: () => descriptor.write(utf8.encode("on write descriptor"))
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead?.color,
        ),
      ),
    );
  }
}
