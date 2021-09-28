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
  _FindDevicesScreen(this.rightGloveFound, this.leftGloveFound);

  bool rightGloveFound;
  bool leftGloveFound;

  void updateState(BluetoothDevice device) {
    if (BluetoothSpecification.RIGHT_GLOVE_NAME == device.name) {
      setState(() {
        rightGloveFound = true;
      });
    }
  }

  bool shouldRender(ScanResult scanResult) {
    switch (scanResult.device.name) {
      case (BluetoothSpecification.RIGHT_GLOVE_NAME):
        return !rightGloveFound;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      drawer: NavDrawer(),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: FlutterBlue.instance.scanResults.map((list) => list
                    .where((scanResult) =>
                        scanResult.advertisementData.connectable)
                    .map((scanResult) => scanResult.device)
                    .toList(growable: true)),
                builder: (context, scanResultSnapshot) {
                  return StreamBuilder<List<BluetoothDevice>>(
                      stream: Stream.periodic(Duration(seconds: 2)).asyncMap(
                          (_) => FlutterBlue.instance.connectedDevices),
                      initialData: [],
                      builder: (context, connectedDevicesSnapshot) {
                        List<BluetoothDevice> devices = [];
                        if (scanResultSnapshot.hasData) {
                          devices.addAll(scanResultSnapshot.data!);
                        }
                        if (connectedDevicesSnapshot.hasData) {
                          connectedDevicesSnapshot.data!.forEach((connectedDevice) {
                            if(!devices.map((e) => e.id).contains(connectedDevice.id)){
                                devices.add(connectedDevice);
                            }
                          });
                        }
                        return Column(
                          children: devices
                              .where((d) =>
                                  d.name == BluetoothSpecification.RIGHT_GLOVE_NAME)
                              .map((device) => ConnectionGloveCard(
                                  iconColor: Theme.of(context).primaryColor,
                                  device: device,
                                  updateState: this.updateState,
                                  onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) {
                                        device
                                            .connect()
                                            .then((value) => device.requestMtu(
                                                BluetoothSpecification.mtu))
                                            .catchError((error) {
                                          developer
                                              .log("error connecting ${error}");
                                        });
                                        return DeviceScreen(device: device);
                                      }))))
                              .toSet().toList(),
                        );
                      });
                },
              ),
            ],
          ),
        ),
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
  final Color iconColor;
  final BluetoothDevice device;
  final ValueChanged<BluetoothDevice> updateState;
  final VoidCallback onTap;

  ConnectionGloveCard(
      {Key? key,
      required this.iconColor,
      required this.device,
      required this.updateState,
      required this.onTap})
      : super(key: key);

  @override
  _ConnectionGloveCard createState() => new _ConnectionGloveCard(
      this.iconColor, this.device, this.updateState, this.onTap);
}

class _ConnectionGloveCard extends State {
  final Color iconColor;
  final BluetoothDevice device;
  final ValueChanged<BluetoothDevice> updateState;
  final VoidCallback onTap;
  late bool isConnected;

  _ConnectionGloveCard(
      this.iconColor, this.device, this.updateState, this.onTap);

  Future<void> toggleSwitch(bool value) async {
    if (isConnected == false) {
      setState(() {
        isConnected = true;
      });
      await this.device.connect();
      await this.device.requestMtu(BluetoothSpecification.mtu);
      this.updateState(this.device);
    } else {
      setState(() {
        isConnected = false;
      });
      await this.device.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothDeviceState>(
        stream: device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, deviceStatesSnapshot) {
          this.isConnected =
              (deviceStatesSnapshot.data == BluetoothDeviceState.connected);
          return GestureDetector(
              onTap: onTap,
              child: Card(
                  child: ListTile(
                      leading: Container(
                          child: FittedBox(
                              child: Icon(
                        Icons.bluetooth,
                        color: this.iconColor,
                      ))),
                      title: Text(
                        BluetoothBackend.getSpanishGloveName(device.name),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        this.device.id.toString(),
                        style: Theme.of(context).textTheme.caption,
                      ),
                      trailing: Switch(
                        onChanged: toggleSwitch,
                        value: this.isConnected,
                        activeColor: Theme.of(context).primaryColor,
                        activeTrackColor: Colors.lightGreen,
                        inactiveThumbColor: Colors.black,
                        inactiveTrackColor: Colors.grey,
                      ))));
        });
  }
}
