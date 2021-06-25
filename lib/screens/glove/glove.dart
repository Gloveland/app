import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GlovePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Guante"),
        ),
        body: Center(
          child: Text(
            'Hello, world!',
            textDirection: TextDirection.ltr,
          ),
        ));
  }
}