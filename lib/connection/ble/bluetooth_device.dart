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
  BluetoothDevice device;
  bool _loading;

  _DeviceScreenState(this.device) : _loading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return !_loading;
        },
        child: Scaffold(
            appBar: AppBar(title: Text(device.name)),
            body: !_loading
                ? StreamBuilder<BluetoothDeviceState>(
                    stream: device.state,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (c, snapshot) => Column(
                          children: <Widget>[
                            SwitchListTile(
                              secondary: Container(
                                height: double.infinity,
                                child: Icon(snapshot.data ==
                                        BluetoothDeviceState.connected
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth),
                              ),
                              title: Text('${device.name.toString()}'),
                              subtitle: Text('${device.id}'),
                              onChanged: (btConnectionStatus) async {
                                if (btConnectionStatus) {
                                  setState(() => _loading = true);
                                  await device.connect();
                                  await device.requestMtu(
                                      BluetoothSpecification.MTU_BYTES_SIZE);
                                  setState(() => _loading = false);
                                } else {
                                  setState(() => _loading = true);
                                  await device.disconnect();
                                  await Future.delayed(Duration(seconds: 1));
                                  setState(() => _loading = false);
                                }
                              },
                              value: snapshot.data ==
                                      BluetoothDeviceState.connected
                                  ? true
                                  : false,
                            ),
                            ListTile(title: Text("ID: ${device.id}")),
                            StreamBuilder<int>(
                              stream: device.mtu,
                              initialData: 0,
                              builder: (c, snapshot) {
                                var mtuSize =
                                    snapshot.hasData ? snapshot.data : 0;
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
                                  onPressed: snapshot.data !=
                                          BluetoothDeviceState.connected
                                      ? null
                                      : () {
                                          BluetoothBackend
                                              .sendCalibrationCommand(device);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Row(
                                            children: [
                                              Icon(Icons.lightbulb,
                                                  color: Colors.blue),
                                              SizedBox(width: 20),
                                              Expanded(
                                                  child: Text(
                                                      "Calibrando... espere a que se apague el led azul del dispositivo."))
                                            ],
                                          )));
                                        },
                                  child: const Text('Calibrar'),
                                )),
                          ],
                        ))
                : Dialog(
                    child: Padding(
                        padding: EdgeInsets.all(50),
                        child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            new CircularProgressIndicator(),
                          ],
                        )))));
  }
}
