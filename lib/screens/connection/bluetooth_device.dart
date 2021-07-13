import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/screens/files/storage.dart';
import 'package:lsa_gloves/screens/connection/bluetooth_widgets.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;
  @override
  _DeviceScreenState createState() => _DeviceScreenState(this.device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  _DeviceScreenState(this.device);
  BluetoothDevice device;
  int _ack = 0;

  VoidCallback? connectCallBack() {
    device.connect();
    setState(() {
      _ack = 0;
    });
  }

  VoidCallback? disconnectCallBack() {
    device.disconnect();
  }

  _readGloveMovements(BluetoothCharacteristic characteristic)  async {
    var word = 'HOLA';
    var deviceId = "ac:87:a3:0a:2d:1b";
    var measurementFile = await DeviceMeasurementsFile.create(deviceId, word);
    while(true) {
      String valueRead = await characteristic.read().then((value) => new String.fromCharCodes(value));
      print("READING.... $valueRead");
      if(!valueRead.contains("ack")){
        setState(() {
          _ack = (_ack + 1) > 9? 1: (_ack + 1);
        });
        if(!valueRead.contains("start") && !valueRead.contains("end")){
          var jsonList = "[$valueRead]";
          measurementFile.add(jsonList);
        }
      }
      print("SENDING.... ${_ack}ack");
      await characteristic.write(utf8.encode("${_ack}ack"));
      if(valueRead.contains("end")) {
        measurementFile.save();
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

