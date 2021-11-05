
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

class GloveMeasurement {
  static const int measurementsNumber = 9;
  static const String pinkyLetter = "P";
  static const String ringLetter = "R";
  static const String middleLetter = "M";
  static const String indexLetter = "I";
  static const String thumbLetter = "T";

  final String deviceId;
  final int eventNum;
  final double millis;
  final Finger thumb;
  final Finger index;
  final Finger middle;
  final Finger ring;
  final Finger pinky;

  GloveMeasurement(this.deviceId, this.eventNum,this.millis,this.pinky, this.ring, this.middle, this.index, this.thumb);

  GloveMeasurement.fromJson(Map<String, dynamic> json)
  :  deviceId = json['device_id'], eventNum = json['event_num'],
        millis = json['millis'],
        pinky = Finger.fromJson(json['pinky'] as Map<String, dynamic>),
        ring = Finger.fromJson(json['ring'] as Map<String, dynamic>),
        middle = Finger.fromJson(json['middle'] as Map<String, dynamic>),
        index = Finger.fromJson(json['index'] as Map<String, dynamic>),
        thumb = Finger.fromJson(json['thumb'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'millis': millis,
    'event_num': eventNum,
    'pinky' : pinky.toJson(),
    'ring': ring.toJson(),
    'middle' : middle.toJson(),
    'index' : index.toJson(),
    'thumb': thumb.toJson(),
  };


  static fromFingerMeasurementsList(int eventNum, double millis, String deviceId, List<String> fingerMeasurements) {
    Map<String, Finger> measurementsMap = new Map();

    for (final item in fingerMeasurements) {
      var measurementList = item.substring(1).split(',').where((s) => s.isNotEmpty).map((value) => double.parse(value)).toList();
      if(measurementList.length < measurementsNumber){
        throw new Exception("Error: not enough finger measurements!!");
      }
      var fingerLetter = item.substring(0, 1);
      measurementsMap[fingerLetter] = Finger.fromList(measurementList);
    }
    Finger? pinky = measurementsMap[pinkyLetter];
    Finger? ring = measurementsMap[ringLetter];
    Finger? middle = measurementsMap[middleLetter];
    Finger? index = measurementsMap[indexLetter];
    Finger? thumb = measurementsMap[thumbLetter];
    return new GloveMeasurement(deviceId, eventNum, millis, pinky!, ring!, middle!, index!, thumb!);
  }

  Finger getFinger(FingerValue fingerName) {
    switch (fingerName) {
      case FingerValue.Pinky:
        return pinky;
      case FingerValue.Ring:
        return ring;
      case FingerValue.Middle:
        return middle;
      case FingerValue.Index:
        return index;
      case FingerValue.Thumb:
        return thumb;
    }
  }
}

enum SensorValue {
  Acceleration,
  Gyroscope,
  Inclination
}

extension SensorValueExtension on SensorValue {
  String spanishName() {
    switch (this) {
      case SensorValue.Acceleration:
        return "Acelerómetro";
      case SensorValue.Gyroscope:
        return "Giroscopio";
      case SensorValue.Inclination:
        return "Inclinación";
    }
  }

  String getXLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "x (m/s²)";
      case SensorValue.Gyroscope:
        return "x (º/s)";
      case SensorValue.Inclination:
        return "roll";
    }
  }
  String getYLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "y (m/s²)";
      case SensorValue.Gyroscope:
        return "y (º/s)";
      case SensorValue.Inclination:
        return "pitch";
    }
  }
  String getZLabel() {
    switch (this) {
      case SensorValue.Acceleration:
        return "z (m/s²)";
      case SensorValue.Gyroscope:
        return "z (º/s)";
      case SensorValue.Inclination:
        return "yaw";
    }
  }
}

class Finger {
  final Acceleration acc;
  final Gyro gyro;
  final Inclination inclination;

  Finger(this.acc, this.gyro, this.inclination);

  Finger.fromJson(Map<String, dynamic> json)
      : acc = Acceleration.fromJson(json['acc'] as Map<String, dynamic>),
        gyro = Gyro.fromJson(json['gyro'] as Map<String, dynamic>),
        inclination = Inclination.fromJson(json['inclination']as Map<String, dynamic>);
      Map<String, dynamic> toJson() => {
    'acc': acc.toJson(),
    'gyro': gyro.toJson(),
    'inclination': inclination.toJson(),
  };

  Finger.fromList(List<double> m):
        acc = Acceleration(m[0],m[1], m[2]),
        gyro = Gyro(m[3],m[4], m[5]),
        inclination = Inclination(m[6],m[7], m[8]);

  Vector3 getSensorValues(SensorValue sensorName) {
    switch (sensorName) {
      case SensorValue.Acceleration:
        return acc;
      case SensorValue.Gyroscope:
        return gyro;
      case SensorValue.Inclination:
        return inclination;
    }
  }
}

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

class Inclination with Vector3 {
  final double roll;
  final double pitch;
  final double yaw;
  Inclination(this.roll, this.pitch, this.yaw);

  Inclination.fromJson(Map<String, dynamic> json)
      : roll = json['roll'], pitch = json['pitch'], yaw = json['yaw'];

  Map<String, dynamic> toJson() => {
    'roll': roll,
    'pitch': pitch,
    'yaw': yaw,
  };

  @override
  double getX() => roll;

  @override
  double getY() => pitch;

  @override
  double getZ() => yaw;
}

abstract class Vector3 {
  double getX();
  double getY();
  double getZ();
}

