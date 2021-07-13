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

void connect() async {
  // connect to the socket server
  final socket = await Socket.connect('192.168.1.9', 8080);
  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

  // listen for responses from the server
  socket.listen( // handle data from the server
        (Uint8List data) {
      final serverResponse = String.fromCharCodes(data);
      print('Server: $serverResponse');
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

  // send some messages to the server
  await sendMessage(socket, 'Knock, knock.');
  await sendMessage(socket, 'Banana');
}

Future<void> sendMessage(Socket socket, String message) async {
  print('Client: $message');
  socket.write(message);
  await Future.delayed(Duration(seconds: 2));
}