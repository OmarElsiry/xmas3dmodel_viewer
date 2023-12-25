import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:o3d/o3d.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({Key? key}) : super(key: key);

  @override
  _CameraPreviewPageState createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  late CameraController _controller;
  bool isCameraInitialized = false;
  String? modelPath = 'assets/MyModel.glb'; // Replace with your model path
  bool isModelVisible = true;
  final screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    requestManageExternalStoragePermission();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
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

  Future<void> takeAndSavePhoto(BuildContext context) async {
    final localContext = context;

    try {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isDenied) {
        if (kDebugMode) {
          print('Storage permission is denied');
        }
        return;
      }

      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/3dmodels viewer';
      final fileName = '${Random().nextInt(10000)}.png';

      final screenshotFuture = screenshotController.capture();

      final Uint8List? imageBytes = await screenshotFuture;

      await encodeAndWriteImageInIsolate(imageBytes!, '/');

      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('Photo saved in 3dmodels viewer folder')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving photo: ');
      }
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(content: Text('Failed to save photo')),
      );
    }
  }

  Future<void> encodeAndWriteImageInIsolate(
      Uint8List imageBytes, String filePath) async {
    final ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(_isolatedTask, receivePort.sendPort);

    final Completer completer = Completer<void>();
    final sendPort = await receivePort.first as SendPort;

    sendPort.send({
      'imageBytes': imageBytes,
      'filePath': filePath,
      'completer': completer,
    });

    await completer.future;
  }

  static void _isolatedTask(SendPort sendPort) {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic message) {
      final Uint8List imageBytes = message['imageBytes'];
      final String filePath = message['filePath'];
      final Completer completer = message['completer'];

      try {
        final img.Image capturedImage = img.decodeImage(imageBytes)!;
        final List<int> jpegBytes = img.encodeJpg(capturedImage, quality: 90);

        File(filePath).writeAsBytes(jpegBytes).then((_) {
          completer.complete();
        }).catchError((error) {
          completer.completeError(error);
        });
      } catch (e) {
        completer.completeError(e);
      }
    });
  }

  void requestManageExternalStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      // Permission is already granted, do nothing
      return;
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      // Permission is granted
    } else {
      // Permission is denied
    }
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

    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Camera Preview'),
          actions: [
            IconButton(
              onPressed: () => takeAndSavePhoto(context),
              icon: const Icon(Icons.camera),
            ),
            IconButton(
              onPressed: toggleModelVisibility,
              icon: Icon(
                  isModelVisible ? Icons.visibility : Icons.visibility_off),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller), // Camera preview as the background

            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isModelVisible ? 1.0 : 0.0,
                child: O3D.asset(
                  src: modelPath!,
                  alt: "A 3D model",
                  ar: true,
                  autoRotate: true,
                  cameraControls: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
