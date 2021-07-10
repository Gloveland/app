import 'dart:convert';
import 'dart:io';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lsa_gloves/screens/files/storage.dart';

void uploadFile(SensorMeasurements sensorMeasurements, DateTime datetime) async {

  var fileName = sensorMeasurements.word +'-'+ datetime.toString();

  var protected = Protected(
      ver: "v1",      //always v1
      alg: "none",    //the algorithm used to sign this file. Either HS256 (HMAC-SHA256) or none (required)
      iat: datetime.toUtc().millisecondsSinceEpoch // date when the file was created in seconds since epoch
  );

  var sensor = [
    //thump
    Sensor("thumpAccX","m/s2"),Sensor("thumpAccY","m/s2"), Sensor("thumpAccZ","m/s2"),
    Sensor("thumpGyroX","deg"),Sensor("thumpGyroY","deg"), Sensor("thumpGyroZ","deg"),
    Sensor("thumpRoll","deg"),Sensor("thumpPitch","deg"), Sensor("thumpYaw","deg"),
    /*
    //index
    Sensor("indexAccX","m/s2"),Sensor("indexAccY","m/s2"), Sensor("indexAccZ","m/s2"),
    Sensor("indexGyroX","deg"),Sensor("indexGyroY","deg"), Sensor("indexGyroZ","deg"),
    Sensor("indexRoll","deg"),Sensor("indexPitch","deg"), Sensor("indexYaw","deg"),
    //middle
    Sensor("middleAccX","m/s2"),Sensor("middleAccY","m/s2"), Sensor("middleAccZ","m/s2"),
    Sensor("middleGyroX","deg"),Sensor("middleGyroY","deg"), Sensor("middleGyroZ","deg"),
    Sensor("middleRoll","deg"),Sensor("middlePitch","deg"), Sensor("middleYaw","deg"),
    //ring
    Sensor("ringAccX","m/s2"),Sensor("ringAccY","m/s2"), Sensor("ringAccZ","m/s2"),
    Sensor("ringGyroX","deg"),Sensor("ringGyroY","deg"), Sensor("ringGyroZ","deg"),
    Sensor("ringRoll","deg"),Sensor("ringPitch","deg"), Sensor("ringYaw","deg"),
    //pinky
    Sensor("pinkyAccX","m/s2"),Sensor("pinkyAccY","m/s2"), Sensor("pinkyAccZ","m/s2"),
    Sensor("pinkyGyroX","deg"),Sensor("pinkyGyroY","deg"), Sensor("pinkyGyroZ","deg"),
    Sensor("pinkyRoll","deg"),Sensor("pinkyPitch","deg"), Sensor("pinkyYaw","deg"),
     */
  ];

  var payload = Payload(
      deviceName: sensorMeasurements.deviceId,//globally unique identifier for this device (e.g. MAC address)
      deviceType: "ESP32",// exact model of the device
      //the frequency of the data in this file (in milliseconds). E.g. for 100Hz fill in 10 (new data every 10 ms.)
      intervalMs: 10, //mpu6050 Default Internal 8MHz oscillator (register 0x6B = 0) equals to  1.25 milliseconds
      sensors: sensor,
      values: sensorMeasurements.values
  );

  var edgeImpulseBody = EdgeImpulseBody(protected: protected, signature: "empty", payload: payload);
  print("sending post");
  print(edgeImpulseBody.toJson());

  Secret secret = await SecretLoader(secretPath: "assets/secrets.json").load();

  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.postUrl(Uri.parse('https://ingestion.edgeimpulse.com/api/training/data'));
  request.headers.set('Content-type', 'application/json');
  request.headers.set('x-api-key', secret.apiKey);
  request.headers.set('x-file-name', fileName);
  request.headers.set('x-label', sensorMeasurements.word);
  request.add(utf8.encode(json.encode(edgeImpulseBody)));
  HttpClientResponse response = await request.close();
  String reply = await response.transform(utf8.decoder).join();
  print(reply );
  httpClient.close();
}

class Secret {
  final String apiKey;
  Secret({this.apiKey = ""});
  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    return new Secret(apiKey: jsonMap["api_key"]);
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
  EdgeImpulseBody({required this.protected, required this.signature, required this.payload});

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
    return <String, dynamic>{
      'ver': ver,
      'alg': alg,
      'iat': iat
    };
  }

}


class Payload {
  final String deviceName;
  final String deviceType;
  final double intervalMs;
  final List<Sensor> sensors;
  final List<List<double>> values;

  Payload({
    required this.deviceName,
    required this.deviceType,
    required this.intervalMs,
    required this.sensors,
    required this.values });


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

class Sensor {
  late final String name;
  late final String units;

  Sensor(String name, String units){
    this.name = name;
    this.units = units;
  }


  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'units': units,
    };
  }
}

