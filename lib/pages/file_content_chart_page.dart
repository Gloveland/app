import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'package:lsa_gloves/model/acceleration.dart';
import 'package:lsa_gloves/model/finger.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/model/gyro.dart';
import 'package:lsa_gloves/model/sensor_value.dart';
import 'package:lsa_gloves/model/vector3.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class FileContentChartPage extends StatefulWidget {
  static const routeName = '/fileContentChart';

  const FileContentChartPage({Key? key}) : super(key: key);

  @override
  _FileContentChartPageState createState() => _FileContentChartPageState();
}

class _FileContentChartPageState extends State<FileContentChartPage> {
  int _fingerChosen = 0;

  @override
  Widget build(BuildContext context) {
    BufferedSensorMeasurements sensorMeasurements =
        ModalRoute.of(context)!.settings.arguments as BufferedSensorMeasurements;

    return Consumer<BluetoothBackend>(
        builder: (context, backend, _) => SafeArea(
                child: Scaffold(
              appBar: AppBar(
                title: Text('Visualización'),
              ),
              drawer: NavDrawer(),
              body: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: List<Widget>.generate(
                            FingerValue.values.length, (int index) {
                          return ChoiceChip(
                            label: Text(FingerValue.values[index].spanishName()),
                            selected: _fingerChosen == index,
                            selectedColor: Colors.cyan,
                            onSelected: (bool selected) {
                              setState(() {
                                _fingerChosen = selected ? index : 0;
                              });
                            },
                            backgroundColor: Colors.blue,
                            labelStyle: TextStyle(color: Colors.white),
                          );
                        }),
                      ),
                      Expanded(
                          child: MeasurementsChart(
                              measurements: sensorMeasurements,
                              finger: FingerValue.values[_fingerChosen],
                              key: ValueKey(_fingerChosen),
                              sensor: SensorValue.Acceleration,
                              title: "Aceleracion",
                              legend: false)),
                      Expanded(
                          child: MeasurementsChart(
                              measurements: sensorMeasurements,
                              finger: FingerValue.values[_fingerChosen],
                              key: ValueKey(_fingerChosen),
                              sensor: SensorValue.Gyroscope,
                              title: "Velocidad angular",
                              legend: false)),
                    ],
                  )),
            )));
  }
}

class MeasurementsChart extends StatefulWidget {
  final BufferedSensorMeasurements measurements;
  final FingerValue finger;
  final SensorValue sensor;
  final String title;
  final bool legend;

  const MeasurementsChart(
      {Key? key,
      required this.measurements,
      required this.finger,
      required this.sensor,
      required this.title,
      required this.legend})
      : super(key: key);

  @override
  _MeasurementsChartState createState() =>
      _MeasurementsChartState(measurements, finger, sensor, title, legend);
}

class _MeasurementsChartState extends State<MeasurementsChart> {
  BufferedSensorMeasurements _measurements;
  FingerValue finger;
  String title;
  bool legend;
  SensorValue sensor;
  late ZoomPanBehavior _zoomPanBehavior;

  List<SeriesEntry> _measurementsX = [];
  List<SeriesEntry> _measurementsY = [];
  List<SeriesEntry> _measurementsZ = [];

  _MeasurementsChartState(
      this._measurements, this.finger, this.sensor, this.title, this.legend);

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
        enablePinching: true, enablePanning: true, zoomMode: ZoomMode.xy);
  }

  @override
  Widget build(BuildContext context) {
    double initialTimestamp = 0.0;
    for (var i = 0; i < this._measurements.values.length; i++) {
      if (i == 0) {
        initialTimestamp = this._measurements.timestamps[i] * 1.0;
      }
      var timestamp = (this._measurements.timestamps[i] - initialTimestamp)  * 1.0;
      var fingerValues = getFingerValues(this._measurements.values[i]);
      var sensorValues = this.getSensorValues(fingerValues);
      _measurementsX.add(SeriesEntry(timestamp, sensorValues.getX()));
      _measurementsY.add(SeriesEntry(timestamp, sensorValues.getY()));
      _measurementsZ.add(SeriesEntry(timestamp, sensorValues.getZ()));
    }
    return SfCartesianChart(
        title: ChartTitle(text: this.title),
        zoomPanBehavior: _zoomPanBehavior,
        series: <ChartSeries>[
          LineSeries<SeriesEntry, double>(
              name: 'X',
              dataSource: _measurementsX,
              markerSettings: MarkerSettings(isVisible: true),
              xValueMapper: (SeriesEntry measurement, _) => measurement.x,
              yValueMapper: (SeriesEntry measurement, _) => measurement.y),
          LineSeries<SeriesEntry, double>(
              name: 'Y',
              dataSource: _measurementsY,
              markerSettings: MarkerSettings(isVisible: true),
              xValueMapper: (SeriesEntry measurement, _) => measurement.x,
              yValueMapper: (SeriesEntry measurement, _) => measurement.y),
          LineSeries<SeriesEntry, double>(
              name: 'Z',
              dataSource: _measurementsZ,
              markerSettings: MarkerSettings(isVisible: true),
              xValueMapper: (SeriesEntry measurement, _) => measurement.x,
              yValueMapper: (SeriesEntry measurement, _) => measurement.y),
        ],
        legend: Legend(isVisible: this.legend, position: LegendPosition.bottom),
        primaryXAxis: NumericAxis(numberFormat: NumberFormat("##,###s")));
  }

  List<double> getFingerValues(List<double> m) {
    switch (finger) {
      case FingerValue.Thumb:
        return m.sublist(0, 6);
      case FingerValue.Index:
        return m.sublist(6, 12);
      case FingerValue.Middle:
        return m.sublist(12, 18);
      case FingerValue.Ring:
        return m.sublist(18, 24);
      case FingerValue.Pinky:
        return m.sublist(24);
    }
  }

  Vector3 getSensorValues(List<double> m) {
    switch (this.sensor) {
      case SensorValue.Acceleration:
        return Acceleration(m[0], m[1], m[2]);
      case SensorValue.Gyroscope:
        return Gyro(m[3], m[4], m[5]);
    }
  }
}

class SeriesEntry {
  double x;
  double y;

  SeriesEntry(this.x, this.y);
}
