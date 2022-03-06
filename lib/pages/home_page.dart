import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../navigation/navigation_drawer.dart';
import 'ble_data_collection_page.dart';
import 'ble_devices_connection_page.dart';
import 'data_visualization_page.dart';
import 'file_manager_page.dart';
import 'interpretation_page.dart';

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
            child: GridView.count(
          primary: false,
          padding: const EdgeInsets.all(8),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          crossAxisCount: 2,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => BleGloveConnectionPage(),
                      maintainState: false));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.bluetooth, size: 100),
                      Text(
                        "Conexión",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => FileManagerPage(),
                      maintainState: false));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.file_copy_outlined, size: 100),
                      Text(
                        "Archivos",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => InterpretationPage(),
                      maintainState: false));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.translate, size: 100),
                      Text(
                        "Interpretación",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => BleDataCollectionPage(),
                      maintainState: false));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.handWaveOutline,
                        size: 100,
                      ),
                      Text(
                        "Recolección",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DataVisualizationPage(),
                      maintainState: false));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.chartLine,
                        size: 100,
                      ),
                      Text(
                        "Visualizador",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
            ElevatedButton(
                onPressed: () => {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.informationOutline,
                        size: 100,
                      ),
                      Text(
                        "Acerca",
                        textScaleFactor: 1.5,
                      )
                    ],
                  ),
                )),
          ],
        )));
  }
}
