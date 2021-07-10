import 'dart:convert';
import 'dart:io';


void uploadFile() async {

  var values = [
    [ -9.81, 0.03, 1.21 ],
    [ -9.83, 0.04, 1.27 ],
    [ -9.12, 0.03, 1.23 ],
    [ -9.14, 0.01, 1.25 ]
  ];

  var sensor = [Sensor("accX","m/s2"), Sensor("accY","m/s2"), Sensor("accZ","m/s2")];

  var payload = Payload(
      deviceName: "ac:87:a3:0a:2d:1b",
      deviceType: "DISCO-L475VG-IOT01A",
      intervalMs: 10,
      sensors: sensor,
      values: values
  );
  var protected = Protected(
      ver: "v1",
      alg: "HS256",
      iat: 1625527314
  );
  var edgeImpulseBody = EdgeImpulseBody(protected: protected, signature: "empty", payload: payload);
  print("sending post");
  print(edgeImpulseBody.toJson());

  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.postUrl(Uri.parse('https://ingestion.edgeimpulse.com/api/training/data'));
  request.headers.set('Content-type', 'application/json');
  request.headers.set('x-api-key', 'ei_7223fabc8d9843d8fff520e22a5b6fc5578444d02ea8b610398089e6cbc175ea');
  request.headers.set('x-file-name', 'desdeLaApp');
  request.add(utf8.encode(json.encode(edgeImpulseBody)));
  HttpClientResponse response = await request.close();
  String reply = await response.transform(utf8.decoder).join();
  print(reply );
  httpClient.close();
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
  final int intervalMs;
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

