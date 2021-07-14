import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class WifiPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Text("Socket"),
        ),
        body: Center(
            child: FloatingActionButton(
    onPressed: () => connect(),
    heroTag: "Wifi",
    tooltip: 'Wifi',
    child: Icon(Icons.wifi))));
  }
}


class DeviceInfo {
  final String id;
  final double battery;
  DeviceInfo(this.id, this.battery);

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'], battery = json['battery'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'battery': battery,
  };
}

class Movement {
  final double acc;
  final double gyro;
  Movement(this.acc, this.gyro);

  Movement.fromJson(Map<String, dynamic> json)
      : acc = json['acc'], gyro = json['gyro'];

  Map<String, dynamic> toJson() => {
    'acc': acc,
    'gyro': gyro,
  };
}


void connect() async {
  // connect to the socket server
  final socket = await Socket.connect('192.168.1.9', 8080);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

  // send some messages to the server
  await sendMessage(socket, '5');
  await sendMessage(socket, 'aBc');
  await sendMessage(socket, '1');
  await sendMessage(socket, '2');

  // listen for responses from the server
  socket.listen( // handle data from the server
        (Uint8List data) {
      final serverResponse = String.fromCharCodes(data);
      print('Server: $serverResponse');
      List<String> list = serverResponse.split('\n').where((s) => !s.isEmpty).toList();
      print('list : $list');
      for(int i = 0; i < list.length ; i++){
        String jsonString = list[i];
        try{
          var pkg = DeviceInfo.fromJson(jsonDecode(jsonString));
          print('map to: ${pkg}');
          print('-> ${pkg.toJson().toString()}');
        }catch(Exception){
          var m = Movement.fromJson(jsonDecode(jsonString));
          print('map to: ${m}');
          print('-> ${m.toJson().toString()}');
        }
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


}

Future<void> sendMessage(Socket socket, String message) async {
  print('Client: $message');
  socket.write(message);
  await Future.delayed(Duration(seconds: 2));
}