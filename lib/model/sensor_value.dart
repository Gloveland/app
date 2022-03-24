enum SensorValue {
  Acceleration,
  Gyroscope
}

extension SensorValueExtension on SensorValue {
  String spanishName() {
    switch (this) {
      case SensorValue.Acceleration:
        return "Acelerómetro";
      case SensorValue.Gyroscope:
        return "Giroscopio";
    }
  }

  String getXLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "x (m/s²)";
      case SensorValue.Gyroscope:
        return "x (º/s)";
    }
  }
  String getYLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "y (m/s²)";
      case SensorValue.Gyroscope:
        return "y (º/s)";
    }
  }
  String getZLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "z (m/s²)";
      case SensorValue.Gyroscope:
        return "z (º/s)";
    }
  }
}