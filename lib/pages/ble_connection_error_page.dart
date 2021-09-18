import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BleConnectionErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Wrap(
              direction: Axis.vertical,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: size.height * 0.03,
              children: <Widget>[
                Icon(Icons.error,
                    size: 150, color: Theme.of(context).errorColor),
                Text("Se perdió la conexión bluetooth!",
                    style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.subtitle1!.fontSize,
                        color: Theme.of(context).errorColor))
              ]),
        ));
  }
}
