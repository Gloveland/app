import 'dart:convert';
import 'dart:io';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lsa_gloves/connection/ble/bluetooth_specification.dart';
import 'package:lsa_gloves/datacollection/storage.dart';
import 'dart:developer' as developer;

class EdgeImpulseApiClient {
  static const String TAG = "EdgeImpulseApiClient";
  static const int OK_STATUS_CODE = 200;

  static Future<bool> uploadFile(
      SensorMeasurements sensorMeasurements, DateTime datetime) async {
    var fileName = sensorMeasurements.word + '-' + datetime.toString();

    var protected = Protected(
        ver: "v1",
        //always v1
        alg: "none",
        //the algorithm used to sign this file. Either HS256 (HMAC-SHA256) or none (required)
        iat:  datetime.toUtc().millisecondsSinceEpoch ~/1000.0// date when the file was created in seconds since epoch
        );
    double elapsedTimeSum = 0.0;
    for(var i = sensorMeasurements.timestamps.length -1 ; i > 0 ; i--){
      var elapsedTime = sensorMeasurements.timestamps[i] - sensorMeasurements.timestamps[i-1];
      elapsedTimeSum += elapsedTime ;
    }
    double averageIntervalInMilliseconds = elapsedTimeSum  / (sensorMeasurements.values.length * 1.0);
    developer.log("averageIntervalInMilliseconds: $averageIntervalInMilliseconds", name: TAG);
    var payload = Payload(
        deviceName: sensorMeasurements.deviceId,
        //globally unique identifier for this device (e.g. MAC address)
        deviceType: "ESP32",
        // exact model of the device
        //the frequency of the data in this file (in milliseconds). E.g. for 100Hz fill in 10 (new data every 10 ms.)
        intervalMs: 16,
        //mpu6050 Default Internal 8MHz oscillator (register 0x6B = 0) equals to  1.25 milliseconds
        sensors: EdgeImpulseApiClient.sensorMeasurementNames,
        values: sensorMeasurements.values);

    var edgeImpulseBody = EdgeImpulseBody(
        protected: protected, signature: "empty", payload: payload);
    developer.log("sending post ${edgeImpulseBody.toJson()}", name: TAG);

    Secret secret =
        await SecretLoader(secretPath: "assets/secrets.json").load();

    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.postUrl(
        Uri.parse('https://ingestion.edgeimpulse.com/api/training/data'));
    request.headers.set('Content-type', 'application/json');
    if(BluetoothSpecification.LEFT_GLOVE_NAME == sensorMeasurements.deviceName){
      request.headers.set('x-api-key', secret.leftGloveApiKey);
    }else{
      request.headers.set('x-api-key', secret.rightGloveApiKey);
    }
    request.headers.set('x-file-name', fileName);
      request.headers.set('x-label', sensorMeasurements.word);
    request.add(utf8.encode(json.encode(edgeImpulseBody)));
    HttpClientResponse response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    developer.log(reply, name: TAG);
    httpClient.close();
    return response.statusCode == OK_STATUS_CODE;
  }

  static const sensorMeasurementNames = [
    //thumb
    SensorParameter("thumbAccX", "m/s2"),
    SensorParameter("thumbAccY", "m/s2"),
    SensorParameter("thumbAccZ", "m/s2"),
    SensorParameter("thumbGyroX", "deg"),
    SensorParameter("thumbGyroY", "deg"),
    SensorParameter("thumbGyroZ", "deg"),
    SensorParameter("thumbRoll", "deg"),
    SensorParameter("thumbPitch", "deg"),
    SensorParameter("thumbYaw", "deg"),
    //index
    SensorParameter("indexAccX", "m/s2"),
    SensorParameter("indexAccY", "m/s2"),
    SensorParameter("indexAccZ", "m/s2"),
    SensorParameter("indexGyroX", "deg"),
    SensorParameter("indexGyroY", "deg"),
    SensorParameter("indexGyroZ", "deg"),
    SensorParameter("indexRoll", "deg"),
    SensorParameter("indexPitch", "deg"),
    SensorParameter("indexYaw", "deg"),
    //middle
    SensorParameter("middleAccX", "m/s2"),
    SensorParameter("middleAccY", "m/s2"),
    SensorParameter("middleAccZ", "m/s2"),
    SensorParameter("middleGyroX", "deg"),
    SensorParameter("middleGyroY", "deg"),
    SensorParameter("middleGyroZ", "deg"),
    SensorParameter("middleRoll", "deg"),
    SensorParameter("middlePitch", "deg"),
    SensorParameter("middleYaw", "deg"),
    //ring
    SensorParameter("ringAccX", "m/s2"),
    SensorParameter("ringAccY", "m/s2"),
    SensorParameter("ringAccZ", "m/s2"),
    SensorParameter("ringGyroX", "deg"),
    SensorParameter("ringGyroY", "deg"),
    SensorParameter("ringGyroZ", "deg"),
    SensorParameter("ringRoll", "deg"),
    SensorParameter("ringPitch", "deg"),
    SensorParameter("ringYaw", "deg"),
    //pinky
    SensorParameter("pinkyAccX", "m/s2"),
    SensorParameter("pinkyAccY", "m/s2"),
    SensorParameter("pinkyAccZ", "m/s2"),
    SensorParameter("pinkyGyroX", "deg"),
    SensorParameter("pinkyGyroY", "deg"),
    SensorParameter("pinkyGyroZ", "deg"),
    SensorParameter("pinkyRoll", "deg"),
    SensorParameter("pinkyPitch", "deg"),
    SensorParameter("pinkyYaw", "deg"),
  ];
}

class Secret {
  final String rightGloveApiKey;
  final String leftGloveApiKey;

  Secret({this.rightGloveApiKey = "", this.leftGloveApiKey = ""});

  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    return new Secret(
        rightGloveApiKey: jsonMap["RightGloveLSA-ApiKey"],
        leftGloveApiKey: jsonMap["LeftGloveLSA-ApiKey"]);
  }
}

class SecretLoader {
  final String secretPath;

  SecretLoader({required this.secretPath});

  Future<Secret> load() {
    return rootBundle.loadStructuredData<Secret>(this.secretPath,
        (jsonStr) async {
      final secret = Secret.fromJson(json.decode(jsonStr));
      return secret;
    });
  }
}

/*
* {
    "protected": {
        "ver": "v1",
        "alg": "HS256",
        "iat": 1625527314
    },
    "signature": "emptySignature",
    "payload": {
        "device_name": "ac:87:a3:0a:2d:1b",
        "device_type": "DISCO-L475VG-IOT01A",
        "interval_ms": 10,
        "sensors": [
            { "name": "accX", "units": "m/s2" },
            { "name": "accY", "units": "m/s2" },
            { "name": "accZ", "units": "m/s2" }
        ],
        "values": [
            [ -9.81, 0.03, 1.21 ],
            [ -9.83, 0.04, 1.27 ],
            [ -9.12, 0.03, 1.23 ],
            [ -9.14, 0.01, 1.25 ]
        ]
    }
}
*/

class EdgeImpulseBody {
  final Protected protected;
  final String signature;
  final Payload payload;

  EdgeImpulseBody(
      {required this.protected,
      required this.signature,
      required this.payload});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'protected': protected.toJson(),
      'signature': signature,
      'payload': payload.toJson(),
    };
  }
}

class Protected {
  final String ver;
  final String alg;
  final int iat;

  Protected({required this.ver, required this.alg, required this.iat});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'ver': ver, 'alg': alg, 'iat': iat};
  }
}

class Payload {
  final String deviceName;
  final String deviceType;
  final int intervalMs;
  final List<SensorParameter> sensors;
  final List<List<double>> values;

  Payload(
      {required this.deviceName,
      required this.deviceType,
      required this.intervalMs,
      required this.sensors,
      required this.values});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_name': deviceName,
      'device_type': deviceType,
      'interval_ms': intervalMs,
      'sensors': sensors.map((s) => s.toJson()).toList(),
      'values': values,
    };
  }
}

class SensorParameter {
  final String name;
  final String units;

  const SensorParameter(this.name, this.units);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'units': units,
    };
  }
}
