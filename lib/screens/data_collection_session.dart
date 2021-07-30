import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// Screen to start data collection sessions.
class DataCollectionSessionPage extends StatefulWidget {
  // final BluetoothDevice bluetoothDevice;

  const DataCollectionSessionPage({Key? key}) : super(key: key);

  @override
  _SessionState createState() => _SessionState();
}

class _SessionState extends State<DataCollectionSessionPage> {
  // final BluetoothDevice bluetoothDevice;

  // _SessionState(this.bluetoothDevice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data collection"),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 16),
            Text("Categoría", textAlign: TextAlign.left),
            SizedBox(height: 16),
            buildDropdownButton(<String>["Números"]),
            SizedBox(height: 16),
            Text("Gesto", textAlign: TextAlign.left),
            buildDropdownButton(<String>["1", "2", "3"]),
            Text(
                "Realizar un movimiento con la mano derecha con pausas de un "
                "segundo y repitiendo 5 veces.",
                textAlign: TextAlign.center,
                textScaleFactor: 1.2),
            TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                  overlayColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered))
                        return Colors.blue.withOpacity(0.04);
                      if (states.contains(MaterialState.focused) ||
                          states.contains(MaterialState.pressed))
                        return Colors.blue.withOpacity(0.12);
                      return Colors.blueAccent;
                    },
                  ),
                ),
                onPressed: () {},
                child: Text('Grabar')),
          ],
        ),
      )),
    );
  }

  DropdownButton<String> buildDropdownButton(List<String> items) {
    return DropdownButton(
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        isExpanded: true);
  }
}
