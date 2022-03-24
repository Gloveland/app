
import 'package:lsa_gloves/model/vector3.dart';

/// Class to encapsulate the gyroscope values received from the glove.
class Gyro with Vector3 {
  final double x;
  final double y;
  final double z;
  Gyro (this.x, this.y, this.z);

  Gyro .fromJson(Map<String, dynamic> json)
      : x = json['x'], y = json['y'], z = json['z'];

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
  };

  @override
  double getX() => x;

  @override
  double getY() => y;

  @override
  double getZ() => z;
}