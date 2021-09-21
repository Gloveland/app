import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/widgets/Dialog.dart';
import 'package:flutter/cupertino.dart';

import 'dart:developer' as developer;

import 'package:lsa_gloves/model/glove_measurement.dart';

/// Class to take in charge the responsibility of receiving and processing
/// the measurements taken from the device.
class MeasurementsCollector {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  static const String TAG = "MeasurementsCollector";
  String _deviceId;
  BluetoothCharacteristic _characteristic;
  List<GloveMeasurement> _items;
  StreamSubscription<List<int>>? _subscription;

  MeasurementsCollector(this._deviceId, this._characteristic)
      : _items = [];

  void readMeasurements(BuildContext context) async {
    await this._characteristic.setNotifyValue(true);
    _subscription = this._characteristic.value.listen((data) {
      String stringRead = new String.fromCharCodes(data);
      developer.log("Incoming data: $stringRead", name: TAG);
      readGloveMeasurementsFromBle(stringRead);
    }, onError: (err) {
      developer.log("Error: ${err.toString()}", name: TAG);
    }, onDone: () {
      developer.log("Reading measurements done", name: TAG);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Capturando movimientos..."),
        duration: Duration(seconds: 2)));
  }

  readGloveMeasurementsFromBle(String stringRead) {
    if (stringRead.isEmpty) {
      return;
    }
    if (this._subscription == null || this._subscription!.isPaused) {
      developer.log("skip: subscription is cancelled", name: TAG);
      return;
    }
    var lastCharacter = stringRead.substring(stringRead.length - 1);
    List<String> fingerMeasurements = stringRead
        .substring(0, stringRead.length - 1)
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
    if (fingerMeasurements.length < 6 || lastCharacter != ";") {
      developer.log(
          "last character is not the expected delimiter ';'"
          "have you change the MTU correctly ",
          name: TAG);
      return;
    }
    var eventNum = int.parse(fingerMeasurements.removeAt(0));
    try {
      developer.log('trying to parse');
      var pkg = GloveMeasurement.fromFingerMeasurementsList(
          eventNum, this._deviceId, fingerMeasurements);
      developer.log('map to -> ${pkg.toJson().toString()}');
      this._items.add(pkg);
    } catch (e) {
      developer.log('cant parse : $stringRead  error : ${e.toString()}');
    }
  }

  stopReadings(BuildContext context, String selectedGesture) async {
    if (this._subscription != null) {
     this. _subscription!.cancel();
     this._subscription = null;
      developer.log("Subscription canceled.", name: TAG);
    }
    if (_items.isNotEmpty) {
      saveMessagesInFile(context, selectedGesture, this._items);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Movimientos guardados!"),
          duration: Duration(seconds: 1)));
    } else {
      developer.log("Empty measurment list, nothing to save", name: TAG);
    }
    await _characteristic.setNotifyValue(false);
  }

  saveMessagesInFile(BuildContext context, String selectedGesture,
      List<GloveMeasurement> gloveMeasurements) async {
    if (gloveMeasurements.isEmpty) {
      return;
    }
    //open pop up loading
    Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
    var deviceId = gloveMeasurements.first.deviceId;
    var measurementFile =
        await DeviceMeasurementsFile.create(deviceId, selectedGesture);
    for (int i = 0; i < gloveMeasurements.length; i++) {
      developer
          .log('saving in file -> ${gloveMeasurements[i].toJson().toString()}');
      measurementFile.add(gloveMeasurements[i]);
    }
    await measurementFile.save();
    this._items = [];
    //close pop up loading
    Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop();
  }
}
