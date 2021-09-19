import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ble_devices_connection_page.dart';

class BleConnectionErrorPage extends StatelessWidget {
  static const routeName = '/bleConnectionError';
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text('Error!'),
        ),
        body: Container(
          height: double.maxFinite,
          child: new Stack(
            //alignment:new Alignment(x, y)
            children: <Widget>[
              new Positioned(
                child: Center(
                  child: Wrap(
                      direction: Axis.vertical,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: size.height * 0.03,
                      children: <Widget>[
                        Icon(Icons.error,
                            size: 100, color: Theme.of(context).errorColor),
                        Text("Se perdió la conexión bluetooth!",
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .fontSize,
                                color: Theme.of(context).errorColor)),
                      ]),
                ),
              ),
              new Positioned(
                child: new Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Container(
                        height: 50.0,
                        margin: EdgeInsets.all(10),
                        child: ElevatedButton(
                          onPressed: () =>  Navigator.pushNamedAndRemoveUntil(
                              context, BleGloveConnectionPage.routeName, (_) => false),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Volver a conectar',
                                  style: TextStyle(
                                    color: Theme.of(context).secondaryHeaderColor,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_right,
                                  size: Theme.of(context).buttonTheme.height ,
                                  color: Theme.of(context).secondaryHeaderColor,
                                )
                              ]),
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              minimumSize: Size(double.infinity, 30)),
                        ))),
              )
            ],
          ),
        ));
  }
}
