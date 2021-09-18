
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../navigation/navigation_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      drawer: NavDrawer(),
      body: Center(
          child: Text("QUE PONEMOS EN LA HOME ??"),
    ));
  }


}
