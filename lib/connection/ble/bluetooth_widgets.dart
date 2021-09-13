import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lsa_gloves/pages/ble_data_collection_page.dart';

class ServiceTile extends StatelessWidget {
  final String deviceId;
  final BluetoothService service;
  final List<BluetoothCharacteristic> characteristics;

  const ServiceTile(
      {Key? key,
      required this.deviceId,
      required this.service,
      required this.characteristics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristics.length < 1) {
      return ListTile(
        title: Text('Error en el servicio ${service.uuid.toString()}'),
        subtitle: Text('Caracteristica no encontrada'),
        onTap: () => null,
      );
    } else {
      return Column(
        children: [
          Container(
              width: double.infinity,
              child: Card(
                  child: TextButton(
                child: const Text('Calibrar'),
                onPressed: null,
              ))),
          Container(
              width: double.infinity,
              child: Card(
                child: TextButton(
                    child: const Text('Recolectar datos'),
                    onPressed: () {
                      print(service.uuid);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BleDataCollectionPage(
                              deviceId: deviceId,
                              characteristic: characteristics.first),
                          maintainState: false));
                    }),
              ))
        ],
      );
    }
  }
}
