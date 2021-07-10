import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/screens/files/storage.dart';
import 'package:path/path.dart';

class FileContentPage extends StatelessWidget {
  static const routeName = '/fileContent';

  @override
  Widget build(BuildContext context) {
    final file = ModalRoute.of(context)!.settings.arguments as DeviceMeasurementsFile;

    return Scaffold(
        appBar: AppBar(
        title: Text(basename(file.path)),
    ),
    body: Center(
        child: FileContentWidget(mFile: file)
    ));
  }
}
/// This is the stateful widget that the main application instantiates.
class FileContentWidget extends StatefulWidget {
  final DeviceMeasurementsFile mFile;
  const FileContentWidget({Key? key, required this.mFile}) : super(key: key);

  @override
  State<FileContentWidget> createState() => _FileContentWidget(mFile);
}

/// This is the private State class that goes with MyStatefulWidget.
class _FileContentWidget extends State<FileContentWidget> {
  final DeviceMeasurementsFile mFile;
  _FileContentWidget(this.mFile);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyText1!,
      textAlign: TextAlign.center,
      child: FutureBuilder<String>(
        future: mFile.readJsonContent().then((value) => value.toJson().toString()), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            children = <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('${snapshot.data}',
                    style: Theme.of(context).textTheme.bodyText1!),
              )
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}',
                  style: Theme.of(context).textTheme.headline2!),
              )
            ];
          } else {
            children = <Widget>[
              SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
              Padding(
                padding: EdgeInsets.only(top: 11),
                child: Text('Awaiting result...',
                    style: Theme.of(context).textTheme.headline2!),
              )
            ];
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          );
        },
      ),
    );
  }
}

