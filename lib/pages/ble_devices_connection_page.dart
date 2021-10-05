import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
import '../connection/ble/bluetooth_device.dart';
import 'dart:developer' as developer;

class BleGloveConnectionPage extends StatelessWidget {
  static const routeName = '/bleGloveConnectionPage';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return FindDevicesScreen();
          }
          return BluetoothOffScreen(state: state);
        });
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  _FindDevicesScreen createState() => _FindDevicesScreen(false, false);
}

class _FindDevicesScreen extends State<FindDevicesScreen> {
  _FindDevicesScreen(this.rightGloveConnected, this.leftGloveConnected);

  bool rightGloveConnected;
  bool leftGloveConnected;

  void updateState(BluetoothDevice device) {
    if (BluetoothSpecification.RIGHT_GLOVE_NAME == device.name ||
        BluetoothSpecification.LEFT_GLOVE_NAME == device.name) {
      setState(() {
        rightGloveConnected = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispositivos'),
      ),
      drawer: NavDrawer(),
      body: Column(
        children: <Widget>[
          StreamBuilder<List<BluetoothDevice>>(
            stream: FlutterBlue.instance.scanResults.map((list) => list
                .where((scanResult) => scanResult.advertisementData.connectable)
                .map((scanResult) => scanResult.device)
                .toList(growable: true)),
            builder: (context, scanResultSnapshot) {
              return StreamBuilder<List<BluetoothDevice>>(
                  stream: Stream.periodic(Duration(seconds: 2))
                      .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                  initialData: [],
                  builder: (context, connectedDevicesSnapshot) {
                    List<BluetoothDevice> devices = [];
                    if (scanResultSnapshot.hasData) {
                      devices.addAll(scanResultSnapshot.data!);
                    }
                    if (connectedDevicesSnapshot.hasData) {
                      connectedDevicesSnapshot.data!.forEach((connectedDevice) {
                        if (!devices
                            .map((e) => e.id)
                            .contains(connectedDevice.id)) {
                          devices.add(connectedDevice);
                        }
                      });
                    }
                    return Column(
                      children: devices
                          .where((d) =>
                              d.name == BluetoothSpecification.RIGHT_GLOVE_NAME ||
                                  d.name == BluetoothSpecification.LEFT_GLOVE_NAME)
                          .map((device) => ConnectionGloveCard(
                                device: device,
                                updateState: this.updateState,
                              ))
                          .toSet()
                          .toList(),
                    );
                  });
            },
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class ConnectionGloveCard extends StatefulWidget {
  final BluetoothDevice device;
  final ValueChanged<BluetoothDevice> updateState;

  ConnectionGloveCard(
      {Key? key, required this.device, required this.updateState})
      : super(key: key);

  @override
  _ConnectionGloveCard createState() =>
      new _ConnectionGloveCard(this.device, this.updateState);
}

class _ConnectionGloveCard extends State {
  final BluetoothDevice device;
  final ValueChanged<BluetoothDevice> updateState;
  String connectionStatusText = "Desconectado";
  IconData connectionStatusIcon = Icons.bluetooth;
  BluetoothDeviceState? btDeviceState = BluetoothDeviceState.disconnected;

  _ConnectionGloveCard(this.device, this.updateState);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothDeviceState>(
        stream: device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, deviceStatesSnapshot) {
          updateStatusDisplay(deviceStatesSnapshot.data);
          return Card(
              child: ListTile(
                  leading: Container(
                      height: double.infinity,
                      child: Icon(
                        connectionStatusIcon,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: Text(
                    BluetoothBackend.getSpanishGloveName(device.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    connectionStatusText,
                    style: Theme.of(context).textTheme.caption,
                  ),
                  onTap: () => toggleConnection(c),
                  onLongPress: navigateToDeviceSettings,
                  trailing: IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: navigateToDeviceSettings)));
        });
  }

  void updateStatusDisplay(BluetoothDeviceState? btDeviceState) {
    this.btDeviceState = btDeviceState;
    if (btDeviceState == BluetoothDeviceState.disconnected) {
      connectionStatusText = "Desconectado";
      connectionStatusIcon = Icons.bluetooth;
      return;
    }
    if (btDeviceState == BluetoothDeviceState.connecting) {
      connectionStatusText = "Conectando...";
      connectionStatusIcon = Icons.bluetooth;
      return;
    }
    if (btDeviceState == BluetoothDeviceState.connected) {
      connectionStatusText = "Conectado";
      connectionStatusIcon = Icons.bluetooth_connected;
      return;
    }
    if (btDeviceState == BluetoothDeviceState.disconnecting) {
      connectionStatusText = "Desconectando...";
      connectionStatusIcon = Icons.bluetooth_connected;
      return;
    }
  }

  void navigateToDeviceSettings() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DeviceScreen(device: device)));
  }

  void toggleConnection(BuildContext context) {
    if (btDeviceState != BluetoothDeviceState.connected) {
      this.device.connect().then(
          (value) => device.requestMtu(BluetoothSpecification.MTU_BYTES_SIZE));
      this.updateState(this.device);
    } else {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("¿Desconectar?"),
                content: Text(
                    "Finalizará la conexión con ${device.name.toString()}"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancelar'),
                      child: Text("Cancelar")),
                  TextButton(
                      onPressed: () {
                        device.disconnect();
                        Navigator.pop(context, "Desconectar");
                      },
                      child: Text("Desconectar")),
                ],
              ));
    }
  }
}
