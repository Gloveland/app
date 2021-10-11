import 'package:lsa_gloves/model/glove_measurement.dart';

/// "Interface" for classes that need to react to measurement events.
abstract class MeasurementsListener {

  void onMeasurement(GloveMeasurement measurement);
}