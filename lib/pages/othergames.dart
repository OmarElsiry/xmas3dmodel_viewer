import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:o3d/o3d.dart';
import 'dart:math';
import 'package:image/image.dart' as img;

class GamePage extends StatefulWidget {
  final String modelUrl;

  const GamePage({super.key, required this.modelUrl});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late CameraController _controller;
  bool isCameraInitialized = false;
  bool isModelDownloading = true;
  late Future<void> _initializeControllerFuture;
  late File modelFile = File(''); // Initialize with an empty file
  bool isModelVisible = true;
  final screenshotController = ScreenshotController();
  late final DeviceInfoPlugin deviceInfoPlugin;
  late final String packageName;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    requestManageExternalStoragePermission();
    initializeDeviceInfoAndPackageName();
    setState(() {
      isModelDownloading = true;
    });
  }

  Future<void> initializeDeviceInfoAndPackageName() async {
    deviceInfoPlugin = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    packageName = packageInfo.packageName;
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      _initializeControllerFuture = _controller.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> requestManageExternalStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      // Permission is already granted, do nothing
      return;
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      // Permission is granted
    } else {
      // Permission is denied
      // Handle the case where the user denies the permission
    }
  }

  Future<void> takeAndSavePhoto(BuildContext context) async {
    final localContext = context;

    try {
      // Permission checks and camera initialization...

      // Capture screenshot
      final Uint8List? imageBytes = await screenshotController.capture();

      // Save screenshot to external storage
      final directory = await getExternalStorageDirectory();
      final path = directory!.path;
      if (kDebugMode) {
        print('Saving photo to: $path');
      }
      final fileName = '${Random().nextInt(10000)}.png';
      final fullPath = '$path/$fileName';
      final file = File(fullPath);
      await file.writeAsBytes(imageBytes!);

      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          content: Text('Photo saved in external storage directory'),
        ),
      );

      // Save to Gallery logic
      saveScreenshot(imageBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving photo: $e');
      }
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('Failed to save photo')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleModelVisibility() {
    setState(() {
      isModelVisible = !isModelVisible;
    });
  }

  void saveScreenshot(Uint8List bytes) async {
    final time = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '_')
        .replaceAll('.', '_');
    final name = 'ScreenShot_$time';
    await ImageGallerySaver.saveImage(bytes, name: name);
  }

// encode the screenshote to bytes in parallel to avoid time complexity issues
  Future<void> encodeAndWriteImageInIsolate(
      Uint8List imageBytes, String filePath) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_isolatedTask, receivePort.sendPort);

    final sendPort = await receivePort.first as SendPort;

    final responsePort = ReceivePort();
    sendPort.send({
      'imageBytes': imageBytes,
      'filePath': filePath,
      'responsePort': responsePort.sendPort,
    });

    await responsePort.first;
  }

  static void _isolatedTask(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic message) {
      final Uint8List imageBytes = message['imageBytes'];
      final String filePath = message['filePath'];
      final SendPort responsePort = message['responsePort'];

      try {
        // convert img to bytes
        final img.Image capturedImage = img.decodeImage(imageBytes)!;
        final List<int> jpegBytes = img.encodeJpg(capturedImage, quality: 90);

        File(filePath).writeAsBytes(jpegBytes).then((_) {
          responsePort.send(null);
        }).catchError((error) {
          responsePort.send(error);
        });
      } catch (e) {
        responsePort.send(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Preview'),
        actions: [
          IconButton(
            onPressed: () => takeAndSavePhoto(context),
            icon: const Icon(Icons.camera),
          ),
          IconButton(
            onPressed: toggleModelVisibility,
            icon:
                Icon(isModelVisible ? Icons.visibility : Icons.visibility_off),
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller), // Camera preview as the background
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width, // adjust as needed
                height:
                    MediaQuery.sizeOf(context).height * 0.9, // adjust as needed
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isModelVisible ? 1 : 0.0,
                  child: O3D.network(
                    src: widget.modelUrl,
                    ar: true,
                    autoRotate: true,
                    cameraControls: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
