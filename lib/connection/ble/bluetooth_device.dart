import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
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
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) => SwitchListTile(
              secondary: Container(
                height: double.infinity,
                child: Icon(snapshot.data == BluetoothDeviceState.connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth),
              ),
              title: Text('${device.name.toString()}'),
              subtitle: Text('${device.id}'),
              onChanged: (value) {},
              value: snapshot.data == BluetoothDeviceState.connected
                  ? true
                  : false,
            ),
          ),
          ListTile(title: Text("ID: ${device.id}")),
          StreamBuilder<int>(
            stream: device.mtu,
            initialData: 0,
            builder: (c, snapshot) => ListTile(
              title: Text('MTU Size: ${snapshot.data} bytes'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => device.requestMtu(512),
              ),
            ),
          ),
          ListTile(
              title: Text("Calibración"),
              trailing: IconButton(
                icon: Icon(Icons.settings_backup_restore),
                onPressed: () {},
              )),
          Container(
            padding: EdgeInsets.all(16),
            child: ConsoleWidget(),
          )
        ],
      ),
    );
  }
}

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget({Key? key}) : super(key: key);

  @override
  _ConsoleWidgetState createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).backgroundColor,
      child: Text(">> Calibrating..."),
    );
  }
}

