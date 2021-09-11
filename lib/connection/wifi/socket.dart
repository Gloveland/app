import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/model/movement.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/widgets/Dialog.dart';

const String IP = '192.168.1.9'; //10.0.1.70';

/// Show a connection spinning or a page to record movements
class WifiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Socket>(
        future: Socket.connect(IP, 8080, timeout: Duration(seconds: 5)),
        builder: (context, socket) {
          if (socket.hasData) {
            return MovementRecorderWidget(clientSocket: socket.requireData);
          } else {
            return Scaffold(
                appBar: AppBar(title: Text("Connectting....")),
                body: Center(
                    child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      CircularProgressIndicator(),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0),
                        child: new Text('conectando...'),
                      )
                    ])));
          }
        });
  }
}

/// This is the stateful widget that the main application instantiates.
class MovementRecorderWidget extends StatefulWidget {
  final Socket clientSocket;

  const MovementRecorderWidget({Key? key, required this.clientSocket})
      : super(key: key);

  @override
  State<MovementRecorderWidget> createState() =>
      _MovementRecorderWidget(this.clientSocket, false);
}

/// This is the private State class that goes with MyStatefulWidget.
class _MovementRecorderWidget extends State<MovementRecorderWidget> {
  bool _isRecording;
  final Socket clientSocket;
  final Stream<Uint8List> _clientSocketBroadcast;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  TextEditingController _fileNameFieldController = TextEditingController();
  String _fileNameUserInputValue;
  StreamController<Movement> _streamController;
  List<Movement> _items;

  _MovementRecorderWidget(this.clientSocket, this._isRecording)
      : _fileNameUserInputValue = '',
        _clientSocketBroadcast = clientSocket.asBroadcastStream(),
        _streamController = new StreamController.broadcast(),
        _items = [] {
    _streamController.close();
    this.readFromSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Movement recording'),
        ),
        body: _getRecordingLogList(),
        floatingActionButton: _getRecordingButton());
  }

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
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Guardar los movimientos?'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _fileNameUserInputValue = value;
              });
            },
            controller: _fileNameFieldController,
            decoration: InputDecoration(hintText: "Nombre del archivo"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Descartar');
                setState(() {
                  this._items = [];
                });
              },
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Guardar');
                saveMessagesInFile(_fileNameUserInputValue, this._items);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _getRecordingLogList() {
    return Center(
        child: ListView.builder(
            itemBuilder: (BuildContext context, int index) =>
                _getListElement(index),
            itemCount: _items.length));
  }

  Widget _getListElement(int index) {
    if (index >= _items.length) {
      return Container();
    }
    return Container(
      child: Text(_items[index].toJson().toString()),
    );
  }

  Widget _getRecordingButton() {
    if (_isRecording) {
      return FloatingActionButton(
        child: Icon(Icons.stop),
        onPressed: () => stopRecording(),
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
          onPressed: () => startRecording(),
          heroTag: "startRecording",
          tooltip: 'startRecording',
          child: Icon(Icons.circle));
    }
  }

  readFromSocket() async {
    var socketSubscription = _clientSocketBroadcast.listen(null);

    socketSubscription.onError((error) {
      print('socket subscription error: $error');
      socketSubscription.cancel();
      clientSocket.destroy();
      //TODO Reload WifiPage ?
    });

    socketSubscription.onDone(() {
      print('Server left.....');
      socketSubscription.cancel();
      clientSocket.destroy();
      //TODO Reload WifiPage ?
    });

    socketSubscription.onData((Uint8List data) {
      // handle data from the server
      final serverResponse = String.fromCharCodes(data);
      List<String> list =
          serverResponse.split('\n').where((s) => s.isNotEmpty).toList();
      print('server : $list');
      for (int i = 0; i < list.length; i++) {
        if (this._streamController.isClosed) {
          print("skip: stream controller is close");
        } else {
          try {
            String jsonString = list[i];
            var pkg = Movement.fromJson(jsonDecode(jsonString));
            print('map to -> ${pkg.toJson().toString()}');
            this._streamController.add(pkg);
          } catch (e) {
            print('cant parse : ${list[i]}');
            print('error : ${e.toString()}');
          }
        }
      }
    });
  }

  saveMessagesInFile(String fileName, List<Movement> movements) async {
    if (movements.isEmpty) {
      return;
    }
    //open pop up loading
    Dialogs.showLoadingDialog(context, _keyLoader, "Guardando...");
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

  @override
  Future<void> dispose() async {
    super.dispose();
    _streamController.close();
    await clientSocket.close();
  }
}