import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'camerapreviewpage.dart';
import 'scr_viewer.dart';
import 'othergames.dart'; // Import the modified 3D model page here

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    TextEditingController linkController =
        TextEditingController(); // Controller for the text field

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width / 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CameraPreviewPage()),
                      );
                    },
                    child: const Text('Open Camera'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width / 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ScrViewerPage()),
                      );
                    },
                    child: const Text('View Screenshots'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  width: MediaQuery.sizeOf(context).width - 35,
                  child: TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText:
                          'Enter 3D Model Link', // Placeholder text for the text field
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    String modelLink =
                        linkController.text.trim(); // Get the entered link
                    if (modelLink.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(modelUrl: modelLink),
                        ),
                      );
                      if (kDebugMode) {
                        print(modelLink);
                      }
                    } else {
                      // Handle if the textfield is empty link scenario
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a 3D Model Link')),
                      );
                    }
                  },
                  child: const Text('View 3D Model'),
                ),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  child: Column(
                    children: [
                      const Text(
                        'You can always try other links like ',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      // a text with a properties (say text is a button)
                      InkWell(
                        child: const Text(
                          'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          // You can add the action when the link is tapped here
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
