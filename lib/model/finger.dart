import 'sensor_value.dart';
import 'vector3.dart';
import 'acceleration.dart';
import 'gyro.dart';

/// Enumeration for each of the hand's fingers.
enum FingerValue {
  Pinky,
  Ring,
  Middle,
  Index,
  Thumb
}

extension FingerValueTranslation on FingerValue {
  String spanishName() {
    switch (this) {
      case FingerValue.Pinky:
        return "Meñique";
      case FingerValue.Ring:
        return "Anular";
      case FingerValue.Middle:
        return "Medio";
      case FingerValue.Index:
        return "Índice";
      case FingerValue.Thumb:
        return "Pulgar";
    }
  }
}

/// Class to handle the sensor measurements from a finger's mpu6050.
class Finger {
  final Acceleration acc;
  final Gyro gyro;

  Finger(this.acc, this.gyro);

  Finger.fromJson(Map<String, dynamic> json)
      : acc = Acceleration.fromJson(json['acc'] as Map<String, dynamic>),
        gyro = Gyro.fromJson(json['gyro'] as Map<String, dynamic>);
  Map<String, dynamic> toJson() => {
    'acc': acc.toJson(),
    'gyro': gyro.toJson(),
  };

  Finger.fromList(List<double> m):
        acc = Acceleration(m[0],m[1], m[2]),
        gyro = Gyro(m[3],m[4], m[5]);

  Vector3 getSensorValues(SensorValue sensorName) {
    switch (sensorName) {
      case SensorValue.Acceleration:
        return acc;
      case SensorValue.Gyroscope:
        return gyro;
    }
  }
}