import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScrViewerPage extends StatefulWidget {
  const ScrViewerPage({super.key});

  @override
  ScrViewerPageState createState() => ScrViewerPageState();
}

class ScrViewerPageState extends State<ScrViewerPage> {
  late List<File> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _loadImageFiles();
  }

// This method is responsible for loading image files from the external storage directory.
  Future<void> _loadImageFiles() async {
    // Get the external storage directory.
    final directory = await getExternalStorageDirectory();
    // Get the path of the directory.
    final String path = directory!.path;
    // Create a Directory object with the path.
    final Directory appDir = Directory(path);
    // Check if the directory exists, if not, create it.
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
    // Get a list of all entities in the directory.
    final List<FileSystemEntity> entities = appDir.listSync();

    // Filter the entities to only include files and assign them to _imageFiles.
    _imageFiles = entities.whereType<File>().toList();
    // Call setState to trigger a rebuild of the widget with the new _imageFiles.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshots Viewer'),
      ),
      body: _imageFiles.isEmpty
          ? const Center(child: Text('No screenshots available'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
              itemCount: _imageFiles.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        // opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return Scaffold(
                            backgroundColor: Colors.black.withOpacity(0.7),
                            body: Stack(
                              children: <Widget>[
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.file(
                                      _imageFiles[index],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10.0,
                                  right: 10.0,
                                  child: Row(
                                    children: <Widget>[
                                      IconButton(
                                        icon: const Icon(Icons.share,
                                            color: Colors.white),
                                        onPressed: () {
                                          Share.shareXFiles(
                                            [XFile(_imageFiles[index].path)],
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Image.file(
                    _imageFiles[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
