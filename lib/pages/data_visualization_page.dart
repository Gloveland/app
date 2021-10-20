import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/datacollection/measurements_collector.dart';
import 'package:lsa_gloves/datacollection/measurements_listener.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
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
  String _fingerValue = "Thumb";
  String _sensorValue = "Accelerómetro";
  bool running = false;
  IconData _fabIcon = Icons.play_arrow;
  MeasurementsCollector _measurementsCollector =
  MeasurementsCollector(/* writeToFile= */ false);

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothBackend>(
        builder: (context, backend, _) =>
            SafeArea(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('Dispositivos'),
                  ),
                  drawer: NavDrawer(),
                  body: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                              hint: Text("Dedo"),
                              isExpanded: true,
                              value: _fingerValue,
                              onChanged: (value) =>
                                  setState(() {
                                    _fingerValue = value!;
                                  }),
                              items: [
                                "Thumb",
                                "Index",
                                "Middle",
                                "Ring",
                                "Pinky"
                              ]
                                  .map((value) =>
                                  DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                                  .toList()),
                          DropdownButton<String>(
                              hint: Text("Sensor"),
                              isExpanded: true,
                              value: _sensorValue,
                              onChanged: (value) =>
                                  setState(() {
                                    _sensorValue = value!;
                                  }),
                              items: [
                                "Accelerómetro",
                                "Giróscopo",
                                "Inclinación"
                              ]
                                  .map((value) =>
                                  DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                                  .toList()),
                          MeasurementsChart(
                              measurementsCollector: _measurementsCollector)
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

  const MeasurementsChart({Key? key, required this.measurementsCollector})
      : super(key: key);

  @override
  _MeasurementsChartState createState() =>
      _MeasurementsChartState(measurementsCollector);
}

class _MeasurementsChartState extends State<MeasurementsChart>
    with MeasurementsListener {
  static const String TAG = "DATA_VISUALIZER";
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

  _MeasurementsChartState(this._measurementsCollector);

  @override
  void initState() {
    super.initState();
    _measurementsCollector.subscribeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      series: <ChartSeries>[
        LineSeries<SeriesEntry, double>(
            dataSource: _measurementsX,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerX = controller;
            }),
        LineSeries<SeriesEntry, double>(
            dataSource: _measurementsY,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerY = controller;
            }),
        LineSeries<SeriesEntry, double>(
            dataSource: _measurementsZ,
            xValueMapper: (SeriesEntry measurement, _) => measurement.x,
            yValueMapper: (SeriesEntry measurement, _) => measurement.y,
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesControllerZ = controller;
            }),
      ],
    );
  }

  @override
  void onMeasurement(GloveMeasurement measurement) {
    measurementsBuffer.add(measurement);
    lastTimestampMs += measurement.elapsedTimeMs;
    _measurementsX.add(SeriesEntry(lastTimestampMs, measurement.pinky.acc.x));
    _measurementsY.add(SeriesEntry(lastTimestampMs, measurement.pinky.acc.y));
    _measurementsZ.add(SeriesEntry(lastTimestampMs, measurement.pinky.acc.z));
    if (measurementsBuffer.length > maxWindowSize) {
      _measurementsX.removeAt(0);
      _measurementsY.removeAt(0);
      _measurementsZ.removeAt(0);
      measurementsBuffer.remove(0);
      _chartSeriesControllerX?.updateDataSource(
          addedDataIndex: maxWindowSize - 1,
          removedDataIndex: 0);
      _chartSeriesControllerY?.updateDataSource(
          addedDataIndex: maxWindowSize - 1,
          removedDataIndex: 0);
      _chartSeriesControllerZ?.updateDataSource(
          addedDataIndex: maxWindowSize - 1,
          removedDataIndex: 0);
    } else {
      int measurementsAmount = _measurementsX.length;
      _chartSeriesControllerX
          ?.updateDataSource(addedDataIndex: measurementsAmount - 1);
      _chartSeriesControllerY
          ?.updateDataSource(addedDataIndex: measurementsAmount - 1);
      _chartSeriesControllerZ
          ?.updateDataSource(addedDataIndex: measurementsAmount - 1);
    }
  }
}


class SeriesEntry {
  double x;
  double y;

  SeriesEntry(this.x, this.y);
}
