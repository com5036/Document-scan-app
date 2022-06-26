import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

late List<CameraDescription> _cameras;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());

}

/// CameraApp is the Main Application.
class CameraApp extends StatefulWidget {
  /// Default Constructor
  const CameraApp({Key? key}) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();

    loadModel();

    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });


    controller.startImageStream((CameraImage img) {

      Tflite.runSegmentationOnFrame(
          bytesList: img.planes.map((plane) {
            return plane.bytes;
          }).toList(),
        imageHeight: img.height,
        imageWidth: img.width,
      );
    });

  }

  loadModel() async {
    String? res;
    res = await Tflite.loadModel(
        model: "assets/lite-model_edgetpu_vision_autoseg-edgetpu_fused_argmax_xs_1.tflite",
        labels: "assets/labels.txt",
    );

    print('1');
    print(res);
    print('2');
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

    return MaterialApp(
      home:CameraPreview(controller)
    );
  }
}

