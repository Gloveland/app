import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lsa_gloves/pages/ble_data_collection_page.dart';
import 'package:lsa_gloves/pages/ble_devices_connection_page.dart';
import 'package:lsa_gloves/pages/file_manager_page.dart';
import 'package:lsa_gloves/pages/interpretation_page.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      const DrawerHeader(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
        ),
        child: Text("Lsa gloves"),
      ),
      ListTile(
        leading: Icon(Icons.bluetooth),
        title: const Text("Dispositivos"),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BleGloveConnectionPage(),
              maintainState: false));
        },
      ),
      ListTile(
          leading: Icon(Icons.file_copy),
          title: const Text("Gestor de archivos"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FileManagerPage(), maintainState: false));
          }),
      ListTile(
          leading: Container(
              width: 25,
              height: 25,
              child: ImageIcon(AssetImage("assets/images/waving_hand.png"))),
          title: const Text("Recolectar data"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BleDataCollectionPage(),
                maintainState: false));
          }),
      ListTile(
          leading: Icon(Icons.translate),
          title: const Text("Interpretación"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => InterpretationPage(), maintainState: false));
          })
    ]));
  }
}
