import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/model/finger.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/model/sensor_value.dart';
import 'package:lsa_gloves/model/vector3.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:developer' as developer;

class DataVisualizationPage extends StatefulWidget {
  const DataVisualizationPage({Key? key}) : super(key: key);

  @override
  _DataVisualizationPageState createState() => _DataVisualizationPageState();
}

class _DataVisualizationPageState extends State<DataVisualizationPage> {
  FingerValue _finger = FingerValue.Thumb;
  SensorValue _sensor = SensorValue.Acceleration;
  bool running = false;
  IconData _fabIcon = Icons.play_arrow;
  MeasurementsCollector _measurementsCollector =
      MeasurementsCollector(/* writeToFile= */ false);

  @override
  Widget build(BuildContext context) {
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
                      DropdownButton<FingerValue>(
                          hint: Text("Dedo"),
                          isExpanded: true,
                          value: _finger,
                          onChanged: (value) => setState(() {
                                _finger = value!;
                              }),
                          items: FingerValue.values
                              .map((value) => DropdownMenuItem<FingerValue>(
                                    value: value,
                                    child: Text(value.spanishName()),
                                  ))
                              .toList()),
                      DropdownButton<SensorValue>(
                          hint: Text("Sensor"),
                          isExpanded: true,
                          value: _sensor,
                          onChanged: (value) => setState(() {
                                _sensor = value!;
                              }),
                          items: SensorValue.values
                              .map((value) => DropdownMenuItem<SensorValue>(
                                    value: value,
                                    child: Text(value.spanishName()),
                                  ))
                              .toList()),
                      Expanded(
                        child:MeasurementsChart(
                            key: Key("$_finger-$_sensor"),
                            measurementsCollector: _measurementsCollector,
                            finger: _finger,
                            sensor: _sensor)
                      )

                    ],
                  )),
              floatingActionButton: FloatingActionButton(
                child: Icon(_fabIcon),
                onPressed: backend.connectedDevices.length == 0
                    ? null
                    : () {
                        if (running) {
                          backend.sendStopCommand();
                          setState(() {
                            _fabIcon = Icons.play_arrow;
                          });
                          _measurementsCollector.discardCollection();
                          running = false;
                        } else {
                          backend.sendStartDataCollectionCommand();
                          setState(() {
                            _fabIcon = Icons.stop;
                          });
                          _measurementsCollector.startTestCollection(
                              backend.dataCollectionCharacteristics);
                          running = true;
                        }
                      },
              ),
            )));
  }
}

class MeasurementsChart extends StatefulWidget {
  final MeasurementsCollector measurementsCollector;
  final FingerValue finger;
  final SensorValue sensor;

  const MeasurementsChart(
      {Key? key,
      required this.measurementsCollector,
      required this.finger,
      required this.sensor})
      : super(key: key);

  @override
  _MeasurementsChartState createState() =>
      _MeasurementsChartState(measurementsCollector, this.finger, this.sensor);
}

class _MeasurementsChartState extends State<MeasurementsChart>
    with MeasurementsListener {
  static const String TAG = "MeasurementsChart";

  final FingerValue finger;
  final SensorValue sensor;

  MeasurementsCollector _measurementsCollector;

  List<GloveMeasurement> measurementsBuffer = <GloveMeasurement>[];

  static const int maxWindowSize = 100;
  double lastTimestampMs = 0;
  List<SeriesEntry> _measurementsX = [];
  List<SeriesEntry> _measurementsY = [];
  List<SeriesEntry> _measurementsZ = [];

  ChartSeriesController? _chartSeriesControllerX;
  ChartSeriesController? _chartSeriesControllerY;
  ChartSeriesController? _chartSeriesControllerZ;

  _MeasurementsChartState(
      this._measurementsCollector, this.finger, this.sensor);

  @override
  void initState() {
    super.initState();
    _measurementsCollector.subscribeListener(this);
  }

  @override
  void dispose() {
    super.dispose();
    _measurementsCollector.unsubscribeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      series: <ChartSeries>[
        LineSeries<SeriesEntry, double>(
          name: sensor.getXLabel(),
            dataSource: _measurementsX,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerX = controller;
            }),
        LineSeries<SeriesEntry, double>(
          name: sensor.getYLabel(),
            dataSource: _measurementsY,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerY = controller;
            }),
        LineSeries<SeriesEntry, double>(
          name: sensor.getZLabel(),
            dataSource: _measurementsZ,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerZ = controller;
            }),
      ],
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      primaryXAxis: NumericAxis(
        numberFormat: NumberFormat("##,###s")
      )
    );
  }

  @override
  void onMeasurement(GloveMeasurement measurement) {
    measurementsBuffer.add(measurement);
    lastTimestampMs += measurement.timestampMillis;
    Vector3 sensorValues = measurement.getFinger(finger).getSensorValues(sensor);
    _measurementsX.add(SeriesEntry(lastTimestampMs, sensorValues.getX()));
    _measurementsY.add(SeriesEntry(lastTimestampMs, sensorValues.getY()));
    _measurementsZ.add(SeriesEntry(lastTimestampMs, sensorValues.getZ()));
    if (measurementsBuffer.length > maxWindowSize) {
      _measurementsX.removeAt(0);
      _measurementsY.removeAt(0);
      _measurementsZ.removeAt(0);
      measurementsBuffer.remove(0);
      _chartSeriesControllerX?.updateDataSource(
          addedDataIndex: maxWindowSize - 1, removedDataIndex: 0);
      _chartSeriesControllerY?.updateDataSource(
          addedDataIndex: maxWindowSize - 1, removedDataIndex: 0);
      _chartSeriesControllerZ?.updateDataSource(
          addedDataIndex: maxWindowSize - 1, removedDataIndex: 0);
    } else {
      int measurementsAmount = _measurementsX.length;
      _chartSeriesControllerX?.updateDataSource(
          addedDataIndex: measurementsAmount - 1);
      _chartSeriesControllerY?.updateDataSource(
          addedDataIndex: measurementsAmount - 1);
      _chartSeriesControllerZ?.updateDataSource(
          addedDataIndex: measurementsAmount - 1);
    }
  }
}

class SeriesEntry {
  double x;
  double y;

  SeriesEntry(this.x, this.y);
}
