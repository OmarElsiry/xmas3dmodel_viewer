import 'package:flutter/material.dart';
import 'camerapreviewpage.dart';
import 'scr_viewer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>  const CameraPreviewPage()),
                );
              },
              child: const Text('Open Camera'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScrViewerPage()),
                );
              },
              child: const Text('View Screenshots'),
            ),
          ],
        ),
      ),
    );
  }
}