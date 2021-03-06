import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/glove/glove_measurement.dart';
import 'package:provider/provider.dart';
import 'package:simple_timer/simple_timer.dart';
import 'dart:developer' as developer;

/// Page to run data collections.
class BleDataCollectionPage extends StatefulWidget {
  const BleDataCollectionPage({Key? key}) : super(key: key);

  @override
  _BleDataCollectionState createState() => _BleDataCollectionState();
}

class _BleDataCollectionState extends State<BleDataCollectionPage>
    with SingleTickerProviderStateMixin {
  static const String TAG = "BleDataCollection";
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  bool _isRecording = false;
  MeasurementsCollector _measurementsCollector =
      new MeasurementsCollector(/* writeToFile=*/ true);
  int _collections = 0;

  static const Map<String, List<String>> gesturesMap = {
    "Tiempo":["Antes", "Manana"],
    "Sujeto": ["Campo", "Mama", "Papa", "Lapicera"],
    "Verbos":["Vivir", "Haber", "Ir"],
    "Pronombres": ["Idle","Todos"],
    "Calificativo": ["Azul", "Blanco","Rojo"],
    "Salud": ["Hospital", "Dolor", "Cabeza", "Acidez"],
    "Comida": ["Helado", "Galletitas", "Cafe", "Pan"],
    "Dias": ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado","Domingo"],
    "Preguntas": ["Que?", "Donde?", "Porque?"],
    "Numeros": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "Saludos": ["Hola", "Buenos dias", "Como estas?", "Bien", "Mal", "Gracias"]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Consumer<BluetoothBackend>(builder: (context, backend, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                child: Text(
                  "Categor??a",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 8),
              buildDropdownButton(categories, selectedCategory,
                  (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                  gestures = getGestureList(selectedCategory);
                  selectedGesture = gestures[0];
                });
              }),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: Text(
                  "Gesto",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 8),
              buildDropdownButton(gestures, selectedGesture,
                  (String? newValue) {
                setState(() {
                  this.selectedGesture = newValue!;
                });
              }),
              DataVisualizer(
                  key: Key("$_collections-$_isRecording"), collector: _measurementsCollector),
              Expanded(
                  child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: RecordButton(
                          key: ValueKey(backend.connectedDevices.length),
                          disabled: backend.connectedDevices.isEmpty,
                          onButtonPressed: () =>
                              onRecordButtonPressed(backend)))),
            ],
          );
        }),
      )),
    );
  }

  Future<void> onRecordButtonPressed(BluetoothBackend backend) async {
    if (_isRecording) {
      _stopRecording(backend);
      _collections++;
    } else {
      // await Future.wait([
      //   showDialog(
      //           context: context,
      //           builder: (context) {
      //             return this._countDownDialogBuilder();
      //           })
      //       .then((value) =>
      //           developer.log("CountDown dialog complete", name: TAG))
      // ]);
      setState(() {
        _startRecording(backend);
      });
    }
  }

  Widget _countDownDialogBuilder() {
    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50.0))),
        content: Container(
            height: 200,
            width: 200,
            child: DefaultTextStyle(
                style: Theme.of(context).textTheme.headline2!,
                child: Center(
                    child: AnimatedTextKit(
                  isRepeatingAnimation: false,
                  animatedTexts: [
                    ScaleAnimatedText('3',
                        scalingFactor: 0.1,
                        duration: Duration(milliseconds: 500)),
                    ScaleAnimatedText('2',
                        scalingFactor: 0.1,
                        duration: Duration(milliseconds: 500)),
                    ScaleAnimatedText('1',
                        scalingFactor: 0.1,
                        duration: Duration(milliseconds: 500)),
                    ScaleAnimatedText('ya!',
                        scalingFactor: 0,
                        duration: const Duration(milliseconds: 500)),
                  ],
                  onFinished: () => Navigator.pop(context),
                )))));
  }

  void _startRecording(BluetoothBackend bluetoothBackend) {
    developer.log('startRecording');
      bluetoothBackend.sendStartDataCollectionCommand();
      _measurementsCollector.startCollecting(
          this.selectedGesture, bluetoothBackend.dataCollectionCharacteristics);
      _isRecording = true;
  }

  void _stopRecording(BluetoothBackend bluetoothBackend) async {
    developer.log('stopRecording');
    bluetoothBackend.sendStopCommand();
    _isRecording = false;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              title: Text("Finalizar recolecci??n."),
              content: Text("??Desea guardar los archivos o descartarlos?"),
              actions: [
                TextButton(
                    onPressed: () {
                      _measurementsCollector.discardCollection();
                      Navigator.pop(context, 'Cancelar');
                    },
                    child: Text("Descartar")),
                TextButton(
                    onPressed: () {
                      _measurementsCollector.saveCollection();
                      Navigator.pop(context, 'Guardar');
                    },
                    child: Text("Guardar")),
              ],
            ));
  }

  DropdownButton<String> buildDropdownButton(List<String> values,
      String selectedValue, Function(String?)? onSelected) {
    return DropdownButton(
        isExpanded: true,
        value: selectedValue,
        onChanged: onSelected,
        items: values.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList());
  }



  static List<String> getCategoryList() {
    return gesturesMap.keys.toList();
  }

  static List<String> getGestureList(String category) {
    return gesturesMap[category]!;
  }
}

class RecordButton extends StatefulWidget {
  final Function onButtonPressed;
  final bool disabled;

  const RecordButton(
      {Key? key, required this.disabled, required this.onButtonPressed})
      : super(key: key);

  @override
  _RecordButtonState createState() =>
      _RecordButtonState(disabled, onButtonPressed);
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late TimerController _timerController;
  late bool _isRecording;
  bool _disabled;
  Function onButtonPressed;

  _RecordButtonState(this._disabled, this.onButtonPressed) {
    this._isRecording = false;
    this._timerController = new TimerController(this);
  }

  @override
  Widget build(BuildContext context) {
    developer.log("build _RecordButtonState");
    return Container(
      width: 200,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SimpleTimer(
            controller: _timerController,
            duration: Duration(seconds: 10),
            progressIndicatorColor: Theme.of(context).primaryColor,
            progressTextStyle: TextStyle(color: Colors.transparent),
            strokeWidth: 15,
          ),
          Padding(padding: EdgeInsets.all(24), child: buildRecordingButton()),
        ],
      ),
    );
  }

  Container buildRecordingButton() {
    return Container(
        width: 150.0,
        height: 150.0,
        child: (() {
          if (_isRecording) {
            return IconButton(
              icon: Icon(Icons.stop, color: Colors.red, size: 64),
              onPressed: _disabled
                  ? null
                  : () async {
                      await onButtonPressed.call();
                      _timerController.reset();
                      setState(() {
                        _isRecording = false;
                      });
                    },
            );
          } else {
            return IconButton(
              icon: Icon(Icons.circle,
                  color: _disabled
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColor,
                  size: 64),
              onPressed: _disabled
                  ? null
                  : () async {
                      await onButtonPressed.call();
                      _timerController.start();
                      setState(() {
                        _isRecording = true;
                      });
                    },
            );
          }
        })());
  }
}

class DataVisualizer extends StatefulWidget {
  final MeasurementsCollector collector;

  const DataVisualizer({Key? key, required this.collector}) : super(key: key);

  @override
  _DataVisualizerState createState() => _DataVisualizerState(collector);
}

class _DataVisualizerState extends State<DataVisualizer>
    with MeasurementsListener {
  final MeasurementsCollector collector;
  Map<String, GloveStats> _stats;

  _DataVisualizerState(this.collector):_stats = Map();



  @override
  void initState() {
    super.initState();
    this.collector.subscribeListener(this);
  }

  @override
  void dispose() {
    super.dispose();
    this.collector.unsubscribeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _stats.entries
          .map((entry) => Container(
              margin: EdgeInsets.only(top: 8),
              width: double.infinity,
              padding: EdgeInsets.all(8),
              child: Text(
                  "Guante: ${entry.key} - Event number: ${entry.value.eventNumber} "
                  "- Frequency: ${entry.value.getFrequency().toStringAsFixed(2)}Hz")))
          .toList(),
    );
  }

  @override
  void onMeasurement(GloveMeasurement measurement) {
    setState(() {
      if (!_stats.containsKey(measurement.deviceId)) {
        _stats[measurement.deviceId] = GloveStats();
      }
      _stats[measurement.deviceId]?.update(measurement.eventNum, measurement.timestampMillis);
    });
  }
}

class GloveStats {
  static const String TAG = 'GloveStats';
  int initialMs = -1;
  int accumulatedTimeMs = 1;
  int eventNumber = 1;

  void update(int gloveEventNum, int timestampMillis) {
    if(this.initialMs < 0 ){
      this.initialMs = timestampMillis;
      developer.log("set initialMs -> $initialMs", name: TAG);
    }
    if(gloveEventNum != this.eventNumber ){
      developer.log("se perdieron eventos ?", name: TAG);
      developer.log("eventNumber: $eventNumber gloveEventNum: $gloveEventNum", name: TAG);
    }
    eventNumber++;
    accumulatedTimeMs = timestampMillis;
  }

  double getFrequency() {
    double elapsedTime = ((accumulatedTimeMs - initialMs) * 1.0);
    developer.log("elapsedTime = $accumulatedTimeMs - $initialMs= $elapsedTime", name: TAG);
    if(elapsedTime < 1){
      return 0.0;
    }
    double frequency = 1000.0 * eventNumber / elapsedTime;
    developer.log("frequency= 1000 * $eventNumber /$elapsedTime  = $frequency", name: TAG);
    return frequency;
  }
}
