import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _loadImageFiles() async {
    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/3dmodels viewer';

    final Directory appDir = Directory(path);
    final List<FileSystemEntity> entities = appDir.listSync();

    _imageFiles = entities.whereType<File>().toList();
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
                return Image.file(
                  _imageFiles[index],
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }
}
