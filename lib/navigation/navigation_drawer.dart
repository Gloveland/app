import 'package:flutter/material.dart';
import 'package:lsa_gloves/pages/about_page.dart';
import 'package:lsa_gloves/pages/ble_data_collection_page.dart';
import 'package:lsa_gloves/pages/ble_devices_connection_page.dart';
import 'package:lsa_gloves/pages/data_visualization_page.dart';
import 'package:lsa_gloves/pages/file_manager_page.dart';
import 'package:lsa_gloves/pages/interpretation_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
          leading: Icon(MdiIcons.handWaveOutline),
          title: const Text("Recolectar data"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BleDataCollectionPage(),
                maintainState: false));
          }),
      ListTile(
          leading: Icon(Icons.multiline_chart),
          title: const Text("Visualizar data"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DataVisualizationPage(),
                maintainState: false));
          }),
      ListTile(
          leading: Icon(Icons.translate),
          title: const Text("Interpretación"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => InterpretationPage(),
                maintainState: false));
          }),
      ListTile(
          leading: Icon(Icons.info_outline),
          title: const Text("Acerca"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AboutPage(), maintainState: false));
          })
    ]));
  }
}
