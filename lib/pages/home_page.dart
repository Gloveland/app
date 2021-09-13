
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../navigation/navigation_drawer.dart';

class DataCollectionPage extends StatefulWidget {
  const DataCollectionPage({Key? key}) : super(key: key);

  @override
  _DataCollectionPageState createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {

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
