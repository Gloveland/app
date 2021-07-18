import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/screens/connection/ble/find_connection.dart';
import 'package:lsa_gloves/screens/connection/wifi/socket.dart';
import 'package:lsa_gloves/screens/files/file_content.dart';
import 'package:lsa_gloves/screens/files/file_list.dart';
import 'dart:developer';
import 'package:lsa_gloves/screens/files/storage.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        FileContentPage.routeName: (context) => FileContentPage(),
      },
      title: 'Lengua de señas Argentina',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'LSA Gloves'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String dropdownValue = 'Hola';
  final audioPlayer = AssetsAudioPlayer();

  _playSound() async {
    try {
      await audioPlayer.open(
          Audio("assets/audios/$dropdownValue.mp3"),
          autoStart: true
      );
    } catch(t){
      log('error in audio play: $t');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton(
              value: dropdownValue,
              elevation: 16,
              style: const TextStyle(color: Colors.blueAccent),
              underline: Container(
                height: 2,
                color: Colors.blueAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
              },
              items: <String>['Casa', 'Perro', 'Tomate', 'Hola']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            ),
            FloatingActionButton(
              onPressed: () => _playSound(),
              tooltip: 'Reproducir',
              heroTag: 'Reproducir',
              child: Icon(Icons.play_arrow),
            ),
            FloatingActionButton(
              onPressed: () =>{
                 Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => GloveConnectionPage()
                ))
              },

              heroTag: 'Ble',
              tooltip: 'Ble',
              child: Icon(Icons.bluetooth),
            ),
            FloatingActionButton(
              onPressed: () =>{
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => WifiPage()
                ))
              },
              heroTag: 'Wifi',
              tooltip: 'Wifi',
              child: Icon(Icons.wifi),
            ),
            FloatingActionButton(
              onPressed: () => {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FileManagerPage()
                ))
              },
              heroTag: "Archivos",
              tooltip: 'Archivos',
              child: Icon(Icons.file_copy_sharp),
            ),
          ],
        ),
      ),
       // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


