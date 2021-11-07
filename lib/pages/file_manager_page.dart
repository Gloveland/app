import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:lsa_gloves/datacollection/file_content.dart';
import 'package:lsa_gloves/navigation/navigation_drawer.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/datacollection/storage.dart';

import 'file_content_chart_page.dart';

class FileManagerPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _FileManagerPage();
  }
}

class _FileManagerPage extends State<FileManagerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Gestion de archivos"),
        ),
        drawer: NavDrawer(),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder<List<DeviceMeasurementsFile>>(
                stream: GloveEventsStorage().getListOfFiles().asStream(),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map(
                        (f) => Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: IconButton(
                                  icon: Icon(Icons.folder_open_sharp),
                                  onPressed: () async {
                                    SensorMeasurements measurements = await f.readJsonContent();
                                    Navigator.pushNamed(
                                      context,
                                      FileContentChartPage.routeName,
                                      arguments: measurements,
                                    );
                                  },
                                ),
                                title: Text(basename(f.path)),
                                subtitle: Text(f.lastModified),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_outlined,
                                          color: Theme.of(context)
                                              .iconTheme
                                              .color
                                              ?.withOpacity(0.5)),
                                      onPressed: () async {
                                        await f.deleteFile();
                                        //refresh
                                        setState(() {});
                                      },
                                    ),
                                    UploadButton(onButtonPressed: () =>
                                        uploadFileCallBack(f))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ));
  }

  Future<bool> uploadFileCallBack(DeviceMeasurementsFile file) async {
    var uploadResult = await file.upload();
    if (uploadResult) {
      await file.deleteFile();
      //refresh
      setState(() {});
    }
    return uploadResult;
  }
}

class UploadButton extends StatefulWidget {
  final Function onButtonPressed;

  const UploadButton(
      {Key? key,
      required this.onButtonPressed})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _UploadButton(this.onButtonPressed);
  }
}

enum UploadResult { ready, uploading, failed }

class _UploadButton extends State<UploadButton> {
  UploadResult _status;
  final Function onButtonPressed;

  _UploadButton(this.onButtonPressed): _status = UploadResult.ready;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (Timer t) {
      if(_status == UploadResult.failed){
      setState(() {
        _status = UploadResult.ready;
      });
    }});
  }



  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case UploadResult.uploading:
        return new CircularProgressIndicator();
      case UploadResult.failed:
        return IconButton(
          icon: Icon(Icons.close,
            color: Theme.of(context).errorColor),
            onPressed: null
        );
      default:
        return IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: () async {
              setState(() {
                _status = UploadResult.uploading;
              });
              var result = await onButtonPressed.call();
              if(!result){
                setState(() {
                  _status = UploadResult.failed;
                });
              }
            });
    }


  }
}
