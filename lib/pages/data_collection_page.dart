
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../navigation/navigation_drawer.dart';

class DataCollectionPage extends StatefulWidget {
  const DataCollectionPage({Key? key}) : super(key: key);

  @override
  _DataCollectionPageState createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {
  static final List<String> categories = getCategoryList();
  late String selectedCategory = categories[0];
  late List<String> gestures = getGestureList(selectedCategory);
  late String selectedGesture = gestures[0];
  late MeasurementsCollector _measurementsCollector;

  @override
  void initState() {
    _measurementsCollector = MeasurementsCollector();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      drawer: NavDrawer(),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: StreamBuilder<List<BluetoothDevice>>(
            stream: Stream.periodic(Duration(seconds: 2))
                .asyncMap((_) => BluetoothBackend.getConnectedDevices()),
            initialData: [],
            builder: (c, devicesSnapshot) => Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Categoría",
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
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Instrucción",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Container(
                        width: double.infinity,
                        child: Text(
                          "Realizar movimiento con la mano derecha con pausas de un segundo y repitiendo 5 veces.",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 64),
                    Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularPercentIndicator(
                            radius: 250,
                            lineWidth: 16,
                            percent: 0.2,
                            animation: true,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: Colors.blue),
                        Padding(
                            padding: EdgeInsets.all(24),
                            child: buildRecordingButton(devicesSnapshot)),
                      ],
                    ),
                  ],
                )),
      )),
    );
  }

  bool _recordingStarted = false;
  IconData _buttonIcon = Icons.fiber_manual_record;

  Container buildRecordingButton(
      AsyncSnapshot<List<BluetoothDevice>> devicesSnapshot) {
    return Container(
        width: 150.0,
        height: 150.0,
        child: new RawMaterialButton(
          shape: new CircleBorder(),
          elevation: 0.0,
          fillColor: Colors.blue,
          child: Icon(
            _buttonIcon,
            color: Colors.white,
            size: 64,
          ),
          onPressed: () {
            if (devicesSnapshot.data!.isNotEmpty) {
              if (_recordingStarted) {
                BluetoothBackend.sendCommandToConnectedDevices("stop");
                _measurementsCollector.stopReadings();
                setState(() {
                  _buttonIcon = Icons.fiber_manual_record;
                });
              } else {
                BluetoothBackend.sendCommandToConnectedDevices("start");
                _measurementsCollector.readMeasurements();
                setState(() {
                  _buttonIcon = Icons.stop;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Recolectando mediciones desde: " +
                      devicesSnapshot.data!
                          .map((e) => e.name)
                          .toList()
                          .toString()),
                  duration: Duration(seconds: 2),
                ));
              }
              _recordingStarted = !_recordingStarted;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("¡Los guantes no están conectados!"),
                  duration: Duration(seconds: 2)));
            }
          },
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
    return <String>["Números", "Letras", "Saludo"];
  }

  static List<String> getGestureList(String category) {
    if (category == "Números") {
      return <String>["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    }
    if (category == "Letras") {
      return <String>["a", "b", "c"];
    }
    if (category == "Saludo") {
      return <String>["Hola", "¿Cómo estás?", "Adiós"];
    }
    return [];
  }
}
