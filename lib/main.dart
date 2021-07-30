import 'dart:convert';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/screens/connection/ble/find_connection.dart';
import 'package:lsa_gloves/screens/connection/wifi/socket.dart';
import 'package:lsa_gloves/screens/data_collection_session.dart';
import 'package:lsa_gloves/screens/files/file_content.dart';
import 'package:lsa_gloves/screens/files/file_list.dart';
import 'dart:developer';
import 'package:lsa_gloves/screens/files/storage.dart';
import 'package:lsa_gloves/widgets/navigation_drawer.dart';

import 'model/movement.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'LSA Gloves'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: NavDrawer(),
    );
  }
}

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text(widget.title),
//     ),
//     body: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           DropdownButton(
//             value: dropdownValue,
//             elevation: 16,
//             style: const TextStyle(color: Colors.blueAccent),
//             underline: Container(
//               height: 2,
//               color: Colors.blueAccent,
//             ),
//             onChanged: (String? newValue) {
//               setState(() {
//                 dropdownValue = newValue!;
//               });
//             },
//             items: <String>['Casa', 'Perro', 'Tomate', 'Hola']
//               .map<DropdownMenuItem<String>>((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value),
//             );
//           }).toList(),
//           ),
//           FloatingActionButton(
//             onPressed: () => _playSound(),
//             tooltip: 'Reproducir',
//             heroTag: 'Reproducir',
//             child: Icon(Icons.play_arrow),
//           ),
//           FloatingActionButton(
//             onPressed: () =>{
//                Navigator.of(context).push(MaterialPageRoute(
//                   builder: (context) => GloveConnectionPage()
//               ))
//             },
//
//             heroTag: 'Ble',
//             tooltip: 'Ble',
//             child: Icon(Icons.bluetooth),
//           ),
//           FloatingActionButton(
//             onPressed: () =>{
//               Navigator.of(context).push(MaterialPageRoute(
//                   builder: (context) => WifiPage()
//               ))
//             },
//             heroTag: 'Wifi',
//             tooltip: 'Wifi',
//             child: Icon(Icons.wifi),
//           ),
//           FloatingActionButton(
//             onPressed: () => {
//               Navigator.of(context).push(MaterialPageRoute(
//                   builder: (context) => FileManagerPage()
//               ))
//             },
//             heroTag: "Archivos",
//             tooltip: 'Archivos',
//             child: Icon(Icons.file_copy_sharp),
//           ),
//           FloatingActionButton(
//             onPressed: () => {
//               Navigator.of(context).push(MaterialPageRoute(
//                   builder: (context) => DataCollectionSessionPage()
//               ))
//             },
//             heroTag: "Data Collection",
//             tooltip: 'Data Collection',
//             child: Icon(Icons.fiber_manual_record),
//           ),
//         ],
//       ),
//     ),
//      // This trailing comma makes auto-formatting nicer for build methods.
//   );
// }

