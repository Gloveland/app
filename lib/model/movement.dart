class Movement {
  final String deviceId;
  final int eventNum;
  final Hand hand;

  Movement(this.deviceId, this.eventNum, this.hand);

  Movement.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'], eventNum = json['event_num'],
        hand = Hand.fromJson(json['hand'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'event_num': eventNum,
    'hand': hand.toJson(),
  };

  static fromFingerMeasurementsList(int eventNum, String deviceId, List<String> fingerMeasurements) {
    Map<String, Finger> measurementsMap = new Map();

    for (final item in fingerMeasurements) {
      var measurementList = item.substring(1).split(',').where((s) => s.isNotEmpty).map((value) => double.parse(value)).toList();
      if(measurementList.length < 9){
        throw new Exception("Error: not enough finger measurements!!");
      }
      var fingerLetter = item.substring(0, 1);
      measurementsMap[fingerLetter] = Finger.fromList(measurementList);
    }
    Finger pinky = measurementsMap['P'] ?? (throw new Exception("Pinky measurements not found"));
    Finger ring = measurementsMap['R'] ?? (throw new Exception("Ring measurements not found"));
    Finger middle = measurementsMap['M'] ?? (throw new Exception("Middle measurements not found"));
    Finger index = measurementsMap['I'] ?? (throw new Exception("Index measurements not found"));
    Finger thump = measurementsMap['T'] ?? (throw new Exception("Thump measurements not found"));
    Hand hand = new Hand(pinky, ring, middle, index, thump);
    return new Movement(deviceId, eventNum, hand);
  }
}


class Hand {
  final Finger thump;
  final Finger index;
  final Finger middle;
  final Finger ring;
  final Finger pinky;


  Hand(this.pinky, this.ring, this.middle, this.index, this.thump);

  Hand.fromJson(Map<String, dynamic> json)
      : pinky = Finger.fromJson(json['pinky'] as Map<String, dynamic>),
        ring = Finger.fromJson(json['ring'] as Map<String, dynamic>),
        middle = Finger.fromJson(json['middle'] as Map<String, dynamic>),
        index = Finger.fromJson(json['index'] as Map<String, dynamic>),
        thump = Finger.fromJson(json['thumb'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    'pinky' : pinky.toJson(),
    'ring': ring.toJson(),
    'middle' : middle.toJson(),
    'index' : index.toJson(),
    'thump': thump.toJson(),
  };

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

}
class Acceleration {
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
}

class Gyro {
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
}

class Inclination {
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

}


