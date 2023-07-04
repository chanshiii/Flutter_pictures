import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;// import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http; // 追加
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';


Future<void> main() async {
  // main 関数内で非同期処理を呼び出すための設定
  WidgetsFlutterBinding.ensureInitialized();

  //FireStore利用:変更１
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // デバイスで使用可能なカメラのリストを取得
  final cameras = await availableCameras();

  // 利用可能なカメラのリストから特定のカメラを取得
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera Example',
      theme: ThemeData(),
      home: TakePictureScreen(camera: camera),
    );
  }
}

/// 写真撮影画面
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  // 画像ファイルをFirebaseのストレージバケットにアップロードする関数:change2
  Future<String> uploadImageToFirebase(File imageFile) async {
    try {
      // Firebaseのストレージバケットの参照を取得
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref();

      // 画像ファイルをアップロード
      String fileName = Path.basename(imageFile.path);
      TaskSnapshot snapshot = await storageRef.child('images/$fileName').putFile(imageFile);

    // アップロードが成功した場合の処理
      if (snapshot.state == TaskState.success) {
        // アップロード後の画像のダウンロードURLを取得
        String downloadURL = await snapshot.ref.getDownloadURL();
        // ダウンロードURLを使って何かしらの処理を行うことができます
        return downloadURL;
      } else {
        throw Exception('Error in uploading image');
      }
    } catch (error) {
        print('Error uploading image to Firebase: $error');
        throw error;
      }
    }
  //change2

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 写真を撮る
          final image = await _controller.takePicture();
          // ここでimageファイルを引数にuploadImageToFirebase関数を呼び出す //chage4
          File imgFile = File(image.path);
          String imageUrl = await uploadImageToFirebase(imgFile);
          //change4
          // 表示用の画面に遷移
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(imageUrl: imageUrl),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// 撮影した写真を表示する画面 撮影した写真はブラウザ上で観れるが保存はされない
// class DisplayPictureScreen extends StatelessWidget {
//   const DisplayPictureScreen({Key? key, required this.imagePath})
//       : super(key: key);

//   final String imagePath;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('撮れた写真')),
//       body: Center(child: Image.network(imagePath)),
//     );
//   }
// }


// 撮影した写真を表示する画面 Image.file表示時にエラーで画像が見れない
// class DisplayPictureScreen extends StatelessWidget {
//   const DisplayPictureScreen({Key? key, required this.imagePath})
//       : super(key: key);

//   final String imagePath;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('撮れた写真')),
//       body: Center(child: Image.asset('images/my_image.jpg')),
//     );
//   }
// }

// 撮影ボタンを押した後に画像確認ページで保存しますかボタンを追加した。保存はできない
// class DisplayPictureScreen extends StatelessWidget {
//   const DisplayPictureScreen({Key? key, required this.imagePath})
//       : super(key: key);

//   final String imagePath;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('撮れた写真')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset('images/my_image.jpg'),
//             ElevatedButton(
//               onPressed: () {
//                 _saveImageToFolder(imagePath).then((savedImagePath) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('画像が保存されました：$savedImagePath')),
//                   );
//                 }).catchError((error) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('画像の保存中にエラーが発生しました')),
//                   );
//                 });
//               },
//               child: Text('保存しますか？'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// -----------------------------------------------------
// 撮影後に保存ボタンを追加し、保存に失敗のエラーが出る
  class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({Key? key, required this.imageUrl}) : super(key: key);

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('撮れた写真')),
      body: Center(
        // child: Image.network(imagePath), //change3
        child: Image.network(imageUrl),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveImageToDevice(imageUrl);
        },
        child: Icon(Icons.save),
      ),
    );
  }
  //change3
  // Future<void> _saveImageToDevice(String imagePath, BuildContext context) async {
  //   try {
  //     final imageFile = File(imagePath);
  //     final imageBytes = imageFile.readAsBytesSync();

  //     final base64Image = base64Encode(imageBytes);
  //     final response = await http.post(
  //       Uri.parse('https://example.com/save-image'), // 画像を保存するエンドポイントのURLに置き換えてください
  //       body: {'image': base64Image},
  //     );

      // if (response.statusCode == 200) {  
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('画像を保存しました')),
      //   );
      // } else {  
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('画像の保存に失敗しました')),
      //   );
      // }
    // } catch (e) { 
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('画像の保存に失敗しました')),
  //     );
  //   }
  // }

  // Future<String> _getSavePath() async {
  //   final directory = await getApplicationDocumentsDirectory();
  //   final timestamp = DateTime.now().millisecondsSinceEpoch;
  //   final fileName = 'Image_$timestamp.jpg';
  //   return '${directory.path}/$fileName';
  // }
// -----------------------------------------------------

// 画像をデバイスに保存する関数//all追記
  Future<void> _saveImageToDevice(String imageUrl) async {
    try {
      // Firebase Firestoreの参照を取得
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 新しいドキュメントを作成し、画像のURLを保存
      await firestore.collection('images').add({
        'url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(), // サーバーのタイムスタンプ
      });
    } catch (error) {
      print('Error saving image url to Firestore: $error');
      throw error;
    }
  }
}
//change3