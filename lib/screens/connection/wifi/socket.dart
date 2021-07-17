
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

enum Type { deviceInfo, movement }


class Package {
  int type;

  Package(this.type);

  Package.fromJson(Map<String, dynamic> json)
      : type = json['type'];

  Map<String, dynamic> toJson() => {
    'type': type,
  };

}

class DeviceInfo extends Package {
  final String id;
  final double battery;
  DeviceInfo(this.id, this.battery): super(0);

  DeviceInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'], battery = json['battery'], super.fromJson(json);

  Map<String, dynamic> toJson() {
    var result = super.toJson();
    result.addAll({
      'id': id,
      'battery': battery,
    });
    return result;
  }
}

class Movement extends Package{
  final double acc;
  final double gyro;
  Movement(this.acc, this.gyro): super(1);

  Movement.fromJson(Map<String, dynamic> json)
      : acc = json['acc'], gyro = json['gyro'], super.fromJson(json);

  Map<String, dynamic> toJson(){
    var result = super.toJson();
    result.addAll({
      'acc': acc,
      'gyro': gyro,
    });
    return result;
  }
}


void connect() async {
  // CONNECTION RESET BY PEER
  /*
  print('Request info...');
  Socket skt = await Socket.connect('192.168.1.9', 8080, timeout: Duration(seconds: 5));
  print('Connected to: ${skt.remoteAddress.address}:${skt.remotePort}');
  skt.write('1');
  final data  = await skt.first;
  final serverResponse = String.fromCharCodes(data);
  print('Server: $serverResponse');
  await skt.close();
  skt.destroy();

  print('Request movement reads...');
  Socket socket = await Socket.connect('192.168.1.9', 8080, timeout: Duration(seconds: 5));
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
  socket.write('2');
  final data2  = await socket.first;
  final response = String.fromCharCodes(data2);
  print('Server: $response');
  await socket.close();
  skt.destroy();
  */

  // listen for responses from the server
  print('Request info...');
  Socket socket = await Socket.connect('192.168.1.9', 8080, timeout: Duration(seconds: 5));
  socket.write('2');
  socket.write('1');
  socket.listen( // handle data from the server
        (Uint8List data) {
      final serverResponse = String.fromCharCodes(data);
      print('Server: $serverResponse');
      List<String> list = serverResponse.split('\n').where((s) => s.isNotEmpty).toList();
      print('list : $list');
      for(int i = 0; i < list.length ; i++){
        String jsonString = list[i];
        var pkg = Package.fromJson(jsonDecode(jsonString));
        print('map to: ${pkg}');
        print('-> ${pkg.toJson().toString()}');
        switch (Type.values[pkg.type]) {
          case Type.deviceInfo:{
            var pkg = DeviceInfo.fromJson(jsonDecode(jsonString));
            print('map to: ${pkg}');
            print('-> ${pkg.toJson().toString()}');
          }
          break;
          case Type.movement: {
            var pkg = Movement.fromJson(jsonDecode(jsonString));
            print('map to: ${pkg}');
            print('-> ${pkg.toJson().toString()}');
          }
          break;
          default:
            print('unknown package type');
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