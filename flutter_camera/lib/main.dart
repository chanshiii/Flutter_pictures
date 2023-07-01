import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';


late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}

/// CameraApp is the Main Application.
// class CameraApp extends StatefulWidget {
  /// Default Constructor
  // const CameraApp({Key? key}) : super(key :key);
class CameraApp extends StatelessWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CameraAppHome(),
    );
  }
}

class CameraAppHome extends StatefulWidget {
  const CameraAppHome({Key? key}) : super(key: key);

  @override
  // State<CameraApp> createState() => _CameraAppState();
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraAppHome> {
  late CameraController controller;
  String imagePath = "";//追加

  

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    // }).catchError((Object e) {
    //   if (e is CameraException) {
    //     switch (e.code) {
    //       case 'CameraAccessDenied':
    //         // Handle access errors here.
    //         break;
    //       default:
    //         // Handle other errors here.
    //         break;
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
        body: Center(
          child: CameraPreview(controller),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            //写真撮影
            XFile file = await controller.takePicture();
            imagePath = file.path;
            // final XFile imageFlie = await controller.takePicture();
            // print(imageFlie.path);
            //新しい画面に遷移し、撮影した画像を表示
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: imagePath),
              ),
            );
          },
          child: const Icon(Icons.camera_alt),
        ),
    );
  }
}