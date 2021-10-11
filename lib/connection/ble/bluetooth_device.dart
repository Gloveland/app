import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';

import 'package:provider/provider.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device, required this.isEnabled})
      : super(key: key);
  final BluetoothDevice device;
  final bool isEnabled;

  @override
  _DeviceScreenState createState() =>
      _DeviceScreenState(this.device, this.isEnabled);
}

class _DeviceScreenState extends State<DeviceScreen> {
  _DeviceScreenState(this.device, this._isEnabled);

  BluetoothDevice device;
  bool _isEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: ListView(
        children: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.disconnected,
              builder: (c, snapshot) {
                return Column(children: [
                  SwitchListTile(
                    secondary: Container(
                      height: double.infinity,
                      child: Icon(_isEnabled
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth),
                    ),
                    title: Text('${device.name.toString()}'),
                    subtitle: Text('${device.id}'),
                    onChanged: (bool switchValue) {
                      if (switchValue) {
                        setState(() {
                          _isEnabled = true;
                        });
                        device.connect();
                      } else {
                        setState(() {
                          _isEnabled = false;
                        });
                        device.disconnect();
                      }
                    },
                    value: _isEnabled,
                  ),
                  ListTile(title: Text("ID: ${device.id}")),
                  StreamBuilder<int>(
                    stream: device.mtu,
                    initialData: 0,
                    builder: (c, snapshot) {
                      var mtuSize = snapshot.hasData ? snapshot.data : 0;
                      return ListTile(
                        title: Text('MTU Size: $mtuSize bytes'),
                        trailing: IconButton(
                          icon: Icon(Icons.settings_backup_restore),
                          onPressed: () => device.requestMtu(
                              BluetoothSpecification.MTU_BYTES_SIZE),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30),
                  FractionallySizedBox(
                      widthFactor: 0.5,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 20)),
                        onPressed: (_isEnabled &&
                                snapshot.data == BluetoothDeviceState.connected)
                            ? () {
                                Provider.of<BluetoothBackend>(context, listen: false)
                                    .sendCalibrationCommand(device);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Row(
                                  children: [
                                     Icon(Icons.lightbulb, color: Colors.blue),
                                    SizedBox(width: 20),
                                    Expanded(
                                        child: Text(
                                            "Calibrando... espere a que se apague el led azul del dispositivo."))
                                  ],
                                )));
                              }
                            : null,
                        child: const Text('Calibrar'),
                      )),
                ]);
              }),
        ],
      ),
    );
  }
}
