
import 'package:flutter/material.dart';
import 'package:lsa_gloves/pages/ble_connection_error_page.dart';
import 'package:lsa_gloves/pages/ble_devices_connection_page.dart';
import 'package:lsa_gloves/pages/file_content_chart_page.dart';
import 'package:lsa_gloves/pages/home_page.dart';
import 'package:provider/provider.dart';

import 'connection/ble/bluetooth_backend.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
        create: (_) => BluetoothBackend(),
        child: MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        FileContentChartPage.routeName: (context) => FileContentChartPage(),
        BleGloveConnectionPage.routeName: (context) => BleGloveConnectionPage(),
        BleConnectionErrorPage.routeName: (context) => BleConnectionErrorPage(),
      },
      title: 'Lengua de señas Argentina',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage()//HomePage(),
    );
  }
}

