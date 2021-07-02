import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/screens/files/storage.dart';
import 'package:lsa_gloves/screens/glove/widgets.dart';

class GloveConnectionPage extends StatelessWidget {
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
  get gloveStorage => GloveEventsStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Find Devices'),
    ),
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
              builder: (c, snapshot) => Column(
                children: snapshot.data!
                    .map((d) => ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.id.toString()),
                  trailing: StreamBuilder<BluetoothDeviceState>(
                    stream: d.state,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (c, snapshot) {
                      if (snapshot.data ==
                          BluetoothDeviceState.connected) {
                        return RaisedButton(
                          child: Text('OPEN'),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DeviceScreen(device: d,  storage: gloveStorage))),
                        );
                      }
                      return Text(snapshot.data.toString());
                    },
                  ),
                ))
                    .toList(),
              ),
            ),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (c, snapshot) => Column(
                children: snapshot.data!
                    .map(
                      (r) => ScanResultTile(
                    result: r,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      r.device.connect();
                      return DeviceScreen(device: r.device,  storage: gloveStorage);
                    })),
                  ),
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

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device, required this.storage}) : super(key: key);
  final BluetoothDevice device;
  final GloveEventsStorage storage;
  @override
  _DeviceScreenState createState() => _DeviceScreenState(this.device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  _DeviceScreenState(this.device);
  BluetoothDevice device;
  int _ack = 0;

  VoidCallback? connectCallBack() {
    widget.storage.writeSensorMeasurementRow(" connectCallBack ");
    device.connect();
    setState(() {
      _ack = 0;
    });
  }

  VoidCallback? disconnectCallBack() {
    device.disconnect();
  }

  _readGloveMovements(BluetoothCharacteristic characteristic)  async {
    while(true){
      widget.storage.writeSensorMeasurementRow(" desde readGloveMovements ");
      String valueRead = await characteristic.read().then((value) => new String.fromCharCodes(value));
      print("READING.... $valueRead");
      if(!valueRead.contains("ack")){
        setState(() {
          _ack = (_ack + 1) > 9? 1: (_ack + 1);
        });
      }
      print("SENDING.... ${_ack}ack");
      await characteristic.write(utf8.encode("${_ack}ack"));
      if(valueRead.contains("end")){
        return;
      }
    }
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (bleService) => ServiceTile(
        service: bleService,
        characteristicTiles: bleService.characteristics
            .map(
              (characteristic) => CharacteristicTile(
            characteristic: characteristic,
            onReadPressed: () async {
              await _readGloveMovements(characteristic);
            },
            onWritePressed: () async {
              await characteristic.write(utf8.encode("on write characteristic"), withoutResponse: true);
              await characteristic.read();
            },
            onNotificationPressed: () async {
              await characteristic.setNotifyValue(!characteristic.isNotifying);
              await characteristic.read();
            },
            descriptorTiles: characteristic.descriptors
                .map(
                  (descriptor) => DescriptorTile(
                descriptor: descriptor,
                onReadPressed: () => descriptor.read(),
                onWritePressed: () => descriptor.write(utf8.encode("on write descriptor")),
              ),
            )
                .toList(),
          ),
        )
            .toList(),
      ),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => disconnectCallBack; //device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => connectCallBack; //device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
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
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
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
                  onPressed: () => device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


}

