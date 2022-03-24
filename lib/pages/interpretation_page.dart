import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';

import 'dart:developer' as developer;

import 'package:provider/provider.dart';

/// Page to display the interpretations from the glove.
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
          child: InterpretationsPanel(),
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
      for (MapEntry<BluetoothDevice, BluetoothCharacteristic> entry
          in backend.interpretationCharacteristics.entries) {
        children.add(InterpretationWidget(
          key: Key(entry.key.id.id),
          device: entry.key,
          interpretationCharacteristic: entry.value,
          measurementsCharacteristic:
              backend.dataCollectionCharacteristics[entry.key]!,
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
  final BluetoothCharacteristic measurementsCharacteristic;

  const InterpretationWidget(
      {Key? key,
      required this.device,
      required this.interpretationCharacteristic,
      required this.measurementsCharacteristic})
      : super(key: key);

  @override
  _InterpretationWidgetState createState() => _InterpretationWidgetState(
      device, interpretationCharacteristic, measurementsCharacteristic);
}

class _InterpretationWidgetState extends State<InterpretationWidget> {
  static final String TAG = "InterpretationWidget";
  final BluetoothDevice device;
  final BluetoothCharacteristic interpretationCharacteristic;
  final BluetoothCharacteristic dcCharacteristic;
  final assetsAudioPlayer = AssetsAudioPlayer();
  String previousWord = "";
  String word = "";

  void resetWord() {
    setState(() {
      String previousWord = "";
      String word = "";
    });
  }

  _InterpretationWidgetState(
      this.device, this.interpretationCharacteristic, this.dcCharacteristic);

  @override
  void dispose() {
    super.dispose();
    developer.log("Disposed widget of device: " + device.id.id, name: TAG);
  }

  @override
  Widget build(BuildContext context) {
    var containerDecorator =
        BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
      BoxShadow(
        color: Colors.grey,
        blurRadius: 5.0,
      ),
    ]);

    return Column(
          children: <Widget>[
            displayStats(containerDecorator),
            SizedBox(
                width: double.infinity,
                height: 20,
                child: Text("Dispositivo:",
                    style: TextStyle(color: Theme.of(context).primaryColor))),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.topCenter,
                decoration: containerDecorator,
                child: Text(device.name)),
            SizedBox(
                width: double.infinity,
                height: 20,
                child: Text("Identificador:",
                    style: TextStyle(color: Theme.of(context).primaryColor))),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.topCenter,
                decoration: containerDecorator,
                child: Text("Mac addr: ${device.id.id}")),
            SizedBox(
                width: double.infinity,
                height: 20,
                child: Text("Lectura de los sensores:",
                    style: TextStyle(color: Theme.of(context).primaryColor))),
            StreamBuilder<List<int>>(
                stream: dcCharacteristic.value,
                initialData: [],
                builder: (c, measurements) {
                  String msg = "";
                  if (measurements.hasData) {
                    msg = new String.fromCharCodes(measurements.data!);
                  }
                  return Container(
                      width: double.infinity,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: containerDecorator,
                      child: Text(msg));
                }),
            InterpretationButton(resetWordCallback: () =>
                resetWord())
          ],
        );
  }

  StreamBuilder<List<int>> displayStats(containerDecorator) {
    if (!interpretationCharacteristic.isNotifying) {
      interpretationCharacteristic.setNotifyValue(true);
    }
    return StreamBuilder<List<int>>(
        stream: interpretationCharacteristic.value,
        initialData: [],
        builder: (c, rawDeviceInterpretations) {
          String percentages = "";
          if (rawDeviceInterpretations.hasData) {
            var msg = new String.fromCharCodes(rawDeviceInterpretations.data!);
            developer.log(msg, name: TAG);
            word = getWord(msg);
            percentages = getPercentages(msg);
          }
          if (word != "" && word != previousWord) {
            _playSound(word);
            previousWord = word;
          }
          return Column(children: <Widget>[
            SizedBox(
                width: double.infinity,
                height: 20,
                child: Text("Traducción:",
                    style: TextStyle(color: Theme.of(context).primaryColor))),
            Card(
                elevation: 5,
                child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      alignment: Alignment.center,
                      color: Colors.white,
                      child: Text(word, style: TextStyle(fontSize: 32)),
                    ))),
            SizedBox(
                width: double.infinity,
                height: 20,
                child: Text("Información:",
                    style: TextStyle(color: Theme.of(context).primaryColor))),
            SingleChildScrollView(
                scrollDirection: Axis.vertical,//.horizontal
                child: Container(
                    width: double.infinity,
                    height: 280,
                    alignment: Alignment.center,
                    decoration: containerDecorator,
                    child: Text(percentages))
            ),
          ]);
        });
  }

  String getWord(String interpretationData) {
    final RegExp regexBetweenBrackets = new RegExp(
      r"(?<=\[)(.*?)(?=\])",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regexBetweenBrackets.firstMatch(interpretationData);
    if (match != null && match.groupCount > 0) {
      return match.group(0)!;
    }
    return "";
  }

  String getPercentages(String interpretationData) {
    var percentages = "";
    final RegExp regexBetweenBraces = new RegExp(
        r"(?<=\{)([A-Za-z]*[0-9]*)(?=\:)(.[0-9]?)(?=\})",
        caseSensitive: false);
    Iterable<Match> matches = regexBetweenBraces.allMatches(interpretationData);
    for (Match match in matches) {
      if (match.groupCount > 1) {
        percentages +=
            "  •   ${match.group(1)} → ${match.group(2)!.replaceAll(":", "")}%\n";
      }
    }
    return percentages;
  }

  void _playSound(String word) async {
    try {
      await assetsAudioPlayer.open(Audio("assets/audios/${word.toLowerCase()}.mp3"),
          autoStart: true);
    } catch (t) {
      developer.log('error in audio play: $t', name: TAG);
    }
  }
}

class InterpretationButton extends StatefulWidget {
  final Function resetWordCallback;
  const InterpretationButton({Key? key,
    required this.resetWordCallback})
      : super(key: key);

  @override
  _InterpretationButtonState createState() =>
      _InterpretationButtonState(this.resetWordCallback);
}

class _InterpretationButtonState extends State<InterpretationButton> {
  final Function resetWordCallback;
  bool _isEnabled = false;
  bool _isRunning = false;

  _InterpretationButtonState(this.resetWordCallback);


  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothBackend>(
      builder: (context, backend, _) {
        _isEnabled = backend.connectedDevices.length > 0 ? true : false;
        if (_isEnabled) {
          return ElevatedButton(
              onPressed: () => _onInterpretationButtonPressed(backend),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(10), // Set padding
              ),
              child: Text(_getButtonText(), style: TextStyle(fontSize: 20)));
        } else {
          return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(10), // Set padding
              ),
              child: Text("Traducir", style: TextStyle(fontSize: 20)));
        }
      },
    );
  }

  String _getButtonText() {
    return _isRunning ? "Detener" : "Traducir";
  }

  void _onInterpretationButtonPressed(BluetoothBackend bluetoothBackend) async {
    this.resetWordCallback.call();
    if (_isRunning) {
      bluetoothBackend.sendStopCommand();
    } else {
      bluetoothBackend.sendStartInterpretationCommand();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }
}
