
import 'package:flutter/material.dart';
import 'package:lsa_gloves/datacollection/file_content.dart';
import 'package:lsa_gloves/pages/ble_connection_error_page.dart';
import 'package:lsa_gloves/pages/home_page.dart';

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
      home: BleConnectionErrorPage()//HomePage(),
    );
  }
}

