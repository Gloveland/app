import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';

import 'dart:developer' as developer;

class InterpretationPage extends StatefulWidget {
  const InterpretationPage({Key? key}) : super(key: key);

  @override
  State<InterpretationPage> createState() => _InterpretationPageState();
}

class _InterpretationPageState extends State<InterpretationPage> {
  static final String appBarTitle = 'Interpretación';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      drawer: NavDrawer(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 48,
                  alignment: Alignment.center,
                  color: Theme.of(context).backgroundColor,
                  child: Text(
                    "Traducción",
                    //TODO(https://git.io/Jzuoa): display a definitive interpretation
                    style: TextStyle(fontSize: 32),
                  ),
                ),
                SizedBox(height: 16),
                _devices(),
                Spacer(),
                InterpretationButton()
              ]),
        ),
      ),
    );
  }

  StreamBuilder<List<BluetoothDevice>> _devices() {
    return StreamBuilder<List<BluetoothDevice>>(
        stream: Stream.periodic(Duration(seconds: 2))
            .asyncMap((_) => BluetoothBackend.getConnectedDevices()),
        builder: (c, devicesSnapshot) {
          List<Widget> children = <Widget>[];
          if (devicesSnapshot.hasData) {
            devicesSnapshot.data!.forEach((element) {
              children.add(InterpretationWidget(
                  key: Key(element.id.id), device: element));
              children.add(SizedBox(height: 16));
            });
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );
        });
  }
}

/// Widget to display the interpretations of each glove.
class InterpretationWidget extends StatefulWidget {
  final BluetoothDevice device;

  const InterpretationWidget({Key? key, required this.device})
      : super(key: key);

  @override
  _InterpretationWidgetState createState() =>
      _InterpretationWidgetState(device);
}

class _InterpretationWidgetState extends State<InterpretationWidget> {
  static final String TAG = "InterpretationWidget";
  Stream<List<int>> interpretationStream = Stream.empty();
  final BluetoothDevice device;

  _InterpretationWidgetState(this.device);

  @override
  void initState() {
    super.initState();
    loadInterpretationStream();
  }

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + device.id.id, name: TAG);
  }

  Future<void> loadInterpretationStream() async {
    interpretationStream = await BluetoothBackend.getLsaGlovesService(device)
        .then((service) =>
            BluetoothBackend.getInterpretationCharacteristic(service!))
        .then((characteristic) {
      characteristic.setNotifyValue(true);
      return characteristic.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.topCenter,
                color: Theme.of(context).backgroundColor,
                child: Text(device.name)),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.topCenter,
                color: Theme.of(context).backgroundColor,
                child: Text("Mac addr: ${device.id.id}")),
            displayStats()
          ],
        ));
  }

  StreamBuilder<List<int>> displayStats() {
    return StreamBuilder<List<int>>(
        stream: interpretationStream,
        initialData: [],
        builder: (c, rawDeviceInterpretations) {
          String msg = "";
          if (rawDeviceInterpretations.hasData) {
            msg = new String.fromCharCodes(rawDeviceInterpretations.data!);
          }
          return Container(
              width: double.infinity,
              height: 80,
              alignment: Alignment.center,
              color: Theme.of(c).backgroundColor,
              child: Text(msg));
        });
  }
}

class InterpretationButton extends StatefulWidget {
  const InterpretationButton({Key? key}) : super(key: key);

  @override
  _InterpretationButtonState createState() => _InterpretationButtonState();
}

class _InterpretationButtonState extends State<InterpretationButton> {
  bool _isEnabled = false;
  bool _isRunning = false;
  late StreamSubscription<List<BluetoothDevice>> streamSubscription;

  @override
  void initState() {
    super.initState();
    streamSubscription = Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => BluetoothBackend.getConnectedDevices())
        .listen((devices) {
      if (devices.isEmpty) {
        setState(() {
          _isEnabled = false;
        });
      } else {
        setState(() {
          _isEnabled = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: buildElevatedButton(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    streamSubscription.cancel();
  }

  ElevatedButton buildElevatedButton() {
    if (_isEnabled) {
      return ElevatedButton(
          onPressed: _onInterpretationButtonPressed,
          child: Text(_getButtonText()));
    } else {
      return ElevatedButton(onPressed: null, child: Text("Traducir"));
    }
  }

  String _getButtonText() {
    return _isRunning ? "Detener" : "Traducir";
  }

  void _onInterpretationButtonPressed() async {
    List<BluetoothDevice> connectedDevices =
        await BluetoothBackend.getConnectedDevices();
    if (_isRunning) {
      BluetoothBackend.sendStopCommand(connectedDevices);
    } else {
      BluetoothBackend.sendStartInterpretationCommand(connectedDevices);
    }
    _isRunning = !_isRunning;
  }
}
