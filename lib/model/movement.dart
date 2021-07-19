class Movement {
  final String deviceId;
  final int eventNum;
  final double acc;
  final double gyro;
  Movement(this.deviceId, this.eventNum, this.acc, this.gyro);

  Movement.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'], eventNum = json['event_num'],
        acc = json['acc'], gyro = json['gyro'];

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'event_num': eventNum,
    'acc': acc,
    'gyro': gyro,
  };
}