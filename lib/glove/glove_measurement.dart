import 'finger.dart';

/// Class to represent a glove measurement.
class GloveMeasurement {
  static const int measurementsNumber = 6;
  static const String pinkyLetter = "P";
  static const String ringLetter = "R";
  static const String middleLetter = "M";
  static const String indexLetter = "I";
  static const String thumbLetter = "T";

  final String deviceId;
  final int eventNum;
  final int timestampMillis;
  final Finger thumb;
  final Finger index;
  final Finger middle;
  final Finger ring;
  final Finger pinky;

  GloveMeasurement(this.deviceId, this.eventNum, this.timestampMillis,
      this.pinky, this.ring, this.middle, this.index, this.thumb);

  GloveMeasurement.fromJson(Map<String, dynamic> json)
      : deviceId = json['device_id'],
        eventNum = json['event_num'],
        timestampMillis = json['timestamp_millis'],
        pinky = Finger.fromJson(json['pinky'] as Map<String, dynamic>),
        ring = Finger.fromJson(json['ring'] as Map<String, dynamic>),
        middle = Finger.fromJson(json['middle'] as Map<String, dynamic>),
        index = Finger.fromJson(json['index'] as Map<String, dynamic>),
        thumb = Finger.fromJson(json['thumb'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'timestampMillis': timestampMillis,
        'event_num': eventNum,
        'pinky': pinky.toJson(),
        'ring': ring.toJson(),
        'middle': middle.toJson(),
        'index': index.toJson(),
        'thumb': thumb.toJson(),
      };

  static fromFingerMeasurementsList(int eventNum, int timestampMillis,
      String deviceId, List<String> fingerMeasurements) {
    Map<String, Finger> measurementsMap = new Map();

    for (final item in fingerMeasurements) {
      var measurementList = item
          .substring(1)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((value) => double.parse(value))
          .toList();
      if (measurementList.length < measurementsNumber) {
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
    return new GloveMeasurement(deviceId, eventNum, timestampMillis, pinky!,
        ring!, middle!, index!, thumb!);
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
