import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';

import 'dart:developer' as developer;

import 'package:provider/provider.dart';

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
                InterpretationsPanel(),
                Spacer(),
                InterpretationButton()
              ]),
        ),
      ),
    );
  }
}

class InterpretationsPanel extends StatefulWidget {
  const InterpretationsPanel({Key? key}) : super(key: key);

  @override
  _InterpretationsPanelState createState() => _InterpretationsPanelState();
}

class _InterpretationsPanelState extends State<InterpretationsPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothBackend>(builder: (context, backend, _) {
      List<Widget> children = <Widget>[];
      print(backend.connectedDevices);
      print(backend.controllerCharacteristics);
      for (MapEntry<BluetoothDevice, BluetoothCharacteristic> entry
          in backend.interpretationCharacteristics.entries) {
        children.add(InterpretationWidget(
          key: Key(entry.key.id.id),
          device: entry.key,
          interpretationCharacteristic: entry.value,
        ));
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
  final BluetoothCharacteristic interpretationCharacteristic;

  const InterpretationWidget(
      {Key? key,
      required this.device,
      required this.interpretationCharacteristic})
      : super(key: key);

  @override
  _InterpretationWidgetState createState() =>
      _InterpretationWidgetState(device, interpretationCharacteristic);
}

class _InterpretationWidgetState extends State<InterpretationWidget> {
  static final String TAG = "InterpretationWidget";
  final BluetoothDevice device;
  final BluetoothCharacteristic interpretationCharacteristic;

  _InterpretationWidgetState(this.device, this.interpretationCharacteristic);

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + device.id.id, name: TAG);
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
    if (!interpretationCharacteristic.isNotifying) {
      interpretationCharacteristic.setNotifyValue(true);
    }
    return StreamBuilder<List<int>>(
        stream: interpretationCharacteristic.value,
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
  Iterable<BluetoothCharacteristic> _controllerCharacteristics = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothBackend>(
      builder: (context, backend, _) {
        _isEnabled = backend.connectedDevices.length > 0 ? true : false;
        _controllerCharacteristics = backend.controllerCharacteristics.values;
        return buildElevatedButton();
      },
    );
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
    if (_isRunning) {
      BluetoothBackend.sendStopCommandToControllers(_controllerCharacteristics);
    } else {
      BluetoothBackend.sendStartInterpretationCommandToControllers(
          _controllerCharacteristics);
    }
    _isRunning = !_isRunning;
  }
}
