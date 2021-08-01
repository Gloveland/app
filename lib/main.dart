import 'package:flutter/material.dart';
import 'package:lsa_gloves/screens/files/file_content.dart';
import 'package:lsa_gloves/widgets/data_collection_page.dart';
import 'package:lsa_gloves/widgets/navigation_drawer.dart';

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
      home: DataCollectionPage(),
    );
  }
}

