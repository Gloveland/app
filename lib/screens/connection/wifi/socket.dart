import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class WifiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Socket>(
        future: Socket.connect('192.168.1.9', 8080, timeout: Duration(seconds: 5)),
        builder: (context, socket) {
          if (socket.hasData) {
            return MovementRecorderWidget(clientSocket: socket.requireData);
          } else {
            return Scaffold(
                appBar: AppBar(title: Text("Connectting....")),
                body: Center(child: new Column(
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
  const MovementRecorderWidget({Key? key, required this.clientSocket}) : super(key: key);

  @override
  State<MovementRecorderWidget> createState() => _MovementRecorderWidget(this.clientSocket, false);
}

/// This is the private State class that goes with MyStatefulWidget.
class _MovementRecorderWidget extends State<MovementRecorderWidget> {
  _MovementRecorderWidget(this.clientSocket, this._isRecording);
  Socket clientSocket;
  bool _isRecording;

  StreamController<String> _streamController =  new StreamController.broadcast();
  List<String> items = ["start"];

  @override
  void initState(){
    super.initState();
    /*
    Stream<Uint8List> _socketSuscription = clientSocket.asBroadcastStream(
      onListen: (subscription) {
        subscription.onData((data) {
          print("cancel socket suscription");
        });
        subscription.onDone(() {
          print('Server left.....');
          subscription.cancel();
          clientSocket.destroy();
        });
        subscription.onError((error) {
          print('connection errror: $error');
          subscription.cancel();
          clientSocket.destroy();
        });
      },
      onCancel: (subscription) {
        print("cancel socket suscription");
      },
    );
     */
  }


  @override
  Future<void> dispose() async {
    super.dispose();
    _streamController.close();
    await clientSocket.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movement recording'),
      ),
      body: _getRecordingLogList(),
      floatingActionButton: _getRecordingButton()
    );
  }

  VoidCallback? startRecording() {
    print('startRecording');
    setState(() {
      _isRecording = true;
    });
    print('streamController');
    _streamController =  new StreamController.broadcast();
    _streamController.stream.listen((p) => setState(() => items.add(p)));
    print('load');
    load(_streamController);

  }
  VoidCallback? stopRecording() {
    print('stopRecording');
    _streamController.close();
    setState(() {
      _isRecording = false;
    });

  }

  Widget _getRecordingLogList() {
    return Center(
        child: ListView.builder(
            itemBuilder: (BuildContext context, int index) => _getListElement(index),
            itemCount: items.length
        ));
  }

  Widget _getListElement(int index) {
    if (index >= items.length) {
      return Container();
    }
    return Container(
      child: Text(items[index]),
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
          child: Icon(Icons.circle)
      );
    }
  }


  load(StreamController<String> sc) async {
    //cant susbribe again
    var socketSubscription = clientSocket.listen(null);
    socketSubscription.onError((error) {
      print(error);
      socketSubscription.cancel();
      clientSocket.destroy();
    });
    socketSubscription.onDone(() {
      print('Server left.....');
      socketSubscription.cancel();
      clientSocket.destroy();
    });
    socketSubscription.onData((Uint8List data) {// handle data from the server
      final serverResponse = String.fromCharCodes(data);
      List<String> list = serverResponse.split('\n')
          .where((s) => s.isNotEmpty)
          .toList();
      print('server : $list');
      for (int i = 0; i < list.length; i++) {
        if(sc.isClosed) {
          print("stream controller is close");
          socketSubscription.cancel();
          this.items = ["start"];
          return;
        } else {
          try{
            String jsonString = list[i];
            var pkg = Movement.fromJson(jsonDecode(jsonString));
            print('map to: ${pkg}');
            print('-> ${pkg.toJson().toString()}');
            sc.add(pkg.toJson().toString());
          }catch(e){
            print('cant parse : jsonString');
          }
        }
      }
    });

    /*
    final subscription = getStreamData().listen(null);
    subscription.onData((event) {
      if(sc.isClosed){
        print("stream controller is close");
        subscription.cancel();
        this.items = ["start"];
        return;
      }
      sc.add(event);
    });
     */
  }

  Stream<String> getStreamData() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      yield "1.3, 34.7, 56.778, 45.67, 8.767";
    }
  }

}

class Movement {
  final String deviceId;
  final int eventNum;
  final double acc;
  final double gyro;
  Movement(this.deviceId, this.eventNum, this.acc, this.gyro);

  Movement.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'], eventNum = json['event_num'],
        acc = json['acc'], gyro = json['gyro'];

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'event_num': eventNum,
    'acc': acc,
    'gyro': gyro,
  };
}


void connect() async {
  // listen for responses from the server
  print('Request info...');
  Socket socket = await Socket.connect('192.168.1.9', 8080, timeout: Duration(seconds: 5));

  var suscription = socket.listen((Uint8List data) { // handle data from the server
      final serverResponse = String.fromCharCodes(data);
      print('Server: $serverResponse');
      List<String> list = serverResponse.split('\n').where((s) => s.isNotEmpty).toList();
      print('list : $list');
      for(int i = 0; i < list.length ; i++){
        String jsonString = list[i];
        var pkg = Movement.fromJson(jsonDecode(jsonString));
        print('map to: ${pkg}');
        print('-> ${pkg.toJson().toString()}');
      }
    },
    // handle errors
    onError: (error) {
      print(error);
      socket.destroy();
    },

    // handle server ending connection
    onDone: () {
      print('Server left.....');
      socket.destroy();
    },
  );
  suscription.cancel();
}

