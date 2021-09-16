import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_services.dart';
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

  List<Widget> _buildServiceTiles(
      String deviceId, List<BluetoothService> services) {
    return services
        .where((bleService) =>
            bleService.uuid.toString().toLowerCase() ==
            BluetoothSpecification.LSA_GLOVE_SERVICE_UUID.toLowerCase())
        .map(
          (bleService) => ServiceTile(
            service: bleService,
            deviceId: deviceId,
            characteristics: bleService.characteristics,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          developer.log('Backbutton pressed, disconnecting');
          device.disconnect();
          return Future.value(true);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(device.name),
            actions: <Widget>[
              StreamBuilder<BluetoothDeviceState>(
                stream: device.state,
                initialData: BluetoothDeviceState.connecting,
                builder: (c, snapshot) {
                  String text;
                  switch (snapshot.data) {
                    case BluetoothDeviceState.connected:
                      text = 'CONNECTED';
                      break;
                    case BluetoothDeviceState.disconnected:
                      text = 'DISCONNECTED';
                      break;
                    default:
                      text =
                          snapshot.data.toString().substring(21).toUpperCase();
                      break;
                  }
                  return Center(
                    child: Text(
                      text,
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .primaryTextTheme
                          .button
                          ?.copyWith(color: Colors.white),
                    ),
                  );
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                StreamBuilder<BluetoothDeviceState>(
                  stream: device.state,
                  initialData: BluetoothDeviceState.connecting,
                  builder: (c, snapshot) => ListTile(
                    leading: (snapshot.data == BluetoothDeviceState.connected)
                        ? Icon(Icons.bluetooth_connected)
                        : Icon(Icons.bluetooth_disabled),
                    title: Text(
                        'Device is ${snapshot.data.toString().split('.')[1]}.'),
                    subtitle: Text('${device.id}'),
                    trailing: StreamBuilder<bool>(
                      stream: device.isDiscoveringServices,
                      initialData: false,
                      builder: (c, snapshot) => IndexedStack(
                        index: snapshot.data! ? 1 : 0,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () => device.discoverServices(),
                          ),
                          IconButton(
                            icon: SizedBox(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.red),
                              ),
                              width: 18.0,
                              height: 18.0,
                            ),
                            onPressed: null,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                StreamBuilder<int>(
                  stream: device.mtu,
                  initialData: 0,
                  builder: (c, snapshot) => ListTile(
                    title: Text('MTU Size'),
                    subtitle: Text('${snapshot.data} bytes'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => device.requestMtu(512),
                    ),
                  ),
                ),
                StreamBuilder<List<BluetoothService>>(
                  stream: device.services,
                  initialData: [],
                  builder: (c, snapshot) {
                    return Column(
                      children:
                          _buildServiceTiles('${device.id}', snapshot.data!),
                    );
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
