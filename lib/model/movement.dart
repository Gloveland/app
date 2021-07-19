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
}


class Hand {
  final Finger thump;
  /*
  final Finger index;
  final Finger middle;
  final Finger ring;
  final Finger pinky;
   */

  Hand(this.thump);

  Hand.fromJson(Map<String, dynamic> json)
      : thump = Finger.fromJson(json['thump'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
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


