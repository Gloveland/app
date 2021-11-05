

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lsa_gloves/connection/ble/bluetooth_backend.dart';
import 'package:lsa_gloves/model/glove_measurement.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:developer' as developer;

class FileDataVisualizationPage extends StatefulWidget {
  const FileDataVisualizationPage({Key? key}) : super(key: key);

  @override
  _FileDataVisualizationPageState createState() => _FileDataVisualizationPageState();
}

class _FileDataVisualizationPageState extends State<FileDataVisualizationPage> {

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
                      Expanded(
                          child:MeasurementsChart()
                      )

                    ],
                  )),
            )));
  }
}

class MeasurementsChart extends StatefulWidget {
  final List<GloveMeasurement> measurements;

  const MeasurementsChart(
      {Key? key, required this.measurements})
      : super(key: key);

  @override
  _MeasurementsChartState createState() =>
      _MeasurementsChartState(measurements);
}

class _MeasurementsChartState extends State<MeasurementsChart> {

  SensorValue sensor = SensorValue.Acceleration;

  List<GloveMeasurement> _measurements;
  static const int maxWindowSize = 100;
  List<SeriesEntry> _measurementsX = [];
  List<SeriesEntry> _measurementsY = [];
  List<SeriesEntry> _measurementsZ = [];

  _MeasurementsChartState(
      this._measurements);

  @override
  void initState() {
    super.initState();
    this._measurements.forEach((gloveMeasurement) {
      gloveMeasurement.elapsedTimeMs
      var sensorValues =  gloveMeasurement.getFinger(FingerValue.Thumb).getSensorValues(sensor);
      _measurementsX.add(SeriesEntry(lastTimestampMs, sensorValues.getX()));
      _measurementsY.add(SeriesEntry(lastTimestampMs, sensorValues.getY()));
      _measurementsZ.add(SeriesEntry(lastTimestampMs, sensorValues.getZ()));

    });
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
