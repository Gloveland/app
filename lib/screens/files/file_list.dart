
import 'package:flutter/cupertino.dart';
import 'package:lsa_gloves/screens/files/file_content.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:lsa_gloves/screens/files/storage.dart';


class FileManagerPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion de archivos"),
      ),
      body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<DeviceMeasurementsFile>>(
                stream: GloveEventsStorage().getListOfFiles().asStream(),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((f) => Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: IconButton( icon:  Icon(Icons.folder_open_sharp),
                            onPressed: () async {
                              Navigator.pushNamed(
                                context,
                                FileContentPage.routeName,
                                arguments: f,
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
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                                onPressed: (){ f.deleteFile();},
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.file_upload,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                ),
                                onPressed: (){
                                  f.upload();
                                },
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),).toList(),
                ),
              ),
            ],
          ),
        ),
    );
  }
}



