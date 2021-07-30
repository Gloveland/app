import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lsa_gloves/screens/connection/ble/find_connection.dart';
import 'package:lsa_gloves/screens/connection/wifi/socket.dart';
import 'package:lsa_gloves/screens/files/file_list.dart';

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
              builder: (context) => GloveConnectionPage(),
              maintainState: false));
        },
      ),
      ListTile(
          leading: Icon(Icons.wifi),
          title: const Text("Conexión wifi"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => WifiPage(), maintainState: false));
          }),
      ListTile(
          leading: Icon(Icons.file_copy),
          title: const Text("Gestor de archivos"),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FileManagerPage(), maintainState: false));
          }),
    ]));
  }
}
