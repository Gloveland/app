import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'dart:developer' as developer;

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _DeviceScreenState createState() => _DeviceScreenState(this.device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  _DeviceScreenState(this.device);

  BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: ListView(
        children: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.disconnected,
            builder: (c, snapshot) => SwitchListTile(
              secondary: Container(
                height: double.infinity,
                child: Icon(snapshot.data == BluetoothDeviceState.connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth),
              ),
              title: Text('${device.name.toString()}'),
              subtitle: Text('${device.id}'),
              onChanged: (value) {
                if (value) {
                  setState(() {
                    device.connect().then((value) =>
                        device.requestMtu(BluetoothSpecification.mtu));
                  });
                } else {
                  device.disconnect();
                }
              },
              value: snapshot.data == BluetoothDeviceState.connected
                  ? true
                  : false,
            ),
          ),
          ListTile(title: Text("ID: ${device.id}")),
          StreamBuilder<int>(
            stream: device.mtu,
            initialData: 0,
            builder: (c, snapshot) {
              print("Mtu updated");
              return ListTile(
                title: Text('MTU Size: ${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => device.requestMtu(512),
                ),
              );
            },
          ),
          ListTile(
              title: Text("Calibración"),
              trailing: IconButton(
                icon: Icon(Icons.settings_backup_restore),
                onPressed: () {
                  BluetoothBackend.sendCalibrationCommand(device);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue),
                      SizedBox(width: 20),
                      Expanded(
                          child: Text(
                              "Calibrando... espere a que se apague el led azul del dispositivo."))
                    ],
                  )));
                },
              )),
        ],
      ),
    );
  }
}
