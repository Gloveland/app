import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'navigation_drawer.dart';

class DataCollectionPage extends StatefulWidget {
  const DataCollectionPage({Key? key}) : super(key: key);

  @override
  _DataCollectionPageState createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {
  String selectedCategory = "Números";
  String selectedGesture = "0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LSA Gloves'),
      ),
      drawer: NavDrawer(),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              child: Text(
                "Categoría",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 8),
            DropdownButton(
                isExpanded: true,
                value: selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: <String>["Números"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList()),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: Text(
                "Gesto",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 8),
            DropdownButton(
                isExpanded: true,
                value: selectedGesture,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGesture = newValue!;
                  });
                },
                items: <String>[
                  "0",
                  "1",
                  "2",
                  "3",
                  "4",
                  "5",
                  "6",
                  "7",
                  "8",
                  "9"
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList()),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: Text(
                "Instrucción",
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Container(
                width: double.infinity,
                child: Text(
                  "Realizar movimiento con la mano derecha con pausas de un segundo y repitiendo 5 veces.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 64),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularPercentIndicator(
                    radius: 250,
                    lineWidth:16,
                    percent: 0.2,
                    animation: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.blue),
                Padding(
                    padding: EdgeInsets.all(24),
                    child: Container(
                        width: 150.0,
                        height: 150.0,
                        child: new RawMaterialButton(
                          shape: new CircleBorder(),
                          elevation: 0.0,
                          fillColor: Colors.blue,
                          child: Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () {},
                        ))),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
