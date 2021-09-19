import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
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

class FindDevicesScreen extends StatelessWidget {
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
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (context, connectedDevicesSnapshot) => Column(
                  children: connectedDevicesSnapshot.data!
                      .where((d) => d.name == BluetoothSpecification.deviceName)
                      .map((device) => StreamBuilder<BluetoothDeviceState>(
                            stream: device.state,
                            initialData: BluetoothDeviceState.disconnected,
                            builder: (c, snapshot) {
                              if (snapshot.data ==
                                  BluetoothDeviceState.connected) {
                                return ConnectionGloveCard(
                                  iconColor: Theme.of(context).primaryColor,
                                    device: device,
                                    onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) {
                                          device
                                              .requestMtu(512)
                                              .catchError((error) {
                                            developer.log(
                                                "error connecting ${error}");
                                          });
                                          return DeviceScreen(device: device);
                                        })));
                              }
                              return ConnectionGloveCard(
                                iconColor: Colors.black,
                                  device: device,
                                  onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) {
                                        device
                                            .connect()
                                            .then((value) =>
                                                device.requestMtu(512))
                                            .catchError((error) {
                                          developer
                                              .log("error connecting ${error}");
                                        });
                                        return DeviceScreen(device: device);
                                      })));
                            },
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, scanResultSnapshot) => Column(
                  children: scanResultSnapshot.data!
                      .where((scanResult) =>
                          scanResult.device.name ==
                          BluetoothSpecification.deviceName)
                      .map((scanResult) => ConnectionGloveCard(
                              iconColor: Colors.grey,
                              device: scanResult.device,
                              onTap: () => {
                                    if (scanResult
                                        .advertisementData.connectable)
                                      {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) {
                                          scanResult.device
                                              .connect()
                                              .then((value) => scanResult.device
                                                  .requestMtu(512))
                                              .catchError((error) {
                                            developer.log(
                                                "error connecting ${error}");
                                          });
                                          return DeviceScreen(
                                              device: scanResult.device);
                                        }))
                                      }
                                  })
                          //DisconnectedGloveCard(result: scanResult),
                          )
                      .toList(),
                ),
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

class ConnectionGloveCard extends StatelessWidget {
  const ConnectionGloveCard(
      {Key? key, required this.iconColor, required this.device, required this.onTap})
      : super(key: key);

  final Color iconColor;
  final BluetoothDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  "Guante derecho",
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  this.device.id.toString(),
                  style: Theme.of(context).textTheme.caption,
                ),
                trailing: TextButton(
                    child: const Text('CONNECT'), onPressed: null))));
  }
}
