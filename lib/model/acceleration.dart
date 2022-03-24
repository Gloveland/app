
import 'package:lsa_gloves/glove/vector3.dart';

/// Class to encapsulate the acceleration values received from the glove.
class Acceleration with Vector3 {
  final double x;
  final double y;
  final double z;

  Acceleration(this.x, this.y, this.z);

  Acceleration.fromJson(Map<String, dynamic> json)
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