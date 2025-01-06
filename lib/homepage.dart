import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _controller;
  late Interpreter _interpreter;
  bool _isModelLoaded = false;
  List<Rect> _faceBoxes = [];
  int _numFaces = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/blazeface_short_range.tflite');
    setState(() {
      _isModelLoaded = true;
      debugPrint('************************************ Se cargo el modelo correctamente *****************************************');
    });
    } catch (e) {
      debugPrint('****************************** No se pudo cargar el modelo: $e ****************************************************');
    }
    
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});
    _controller!.startImageStream((CameraImage image) {
      if (_isModelLoaded) {
        _processCameraImage(image);
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image != null) {
        final preprocessedImage = _preprocessImage(image, 128, 128);
        List<List<double>> output = List.generate(1, (_) => List.filled(896 * 16, 0.0));
        _interpreter.run(preprocessedImage, output);
        setState(() {
          _faceBoxes = _getBoundingBoxes(output[0]);
          _numFaces = _faceBoxes.length;
        });
      }
    }
  }

  void _processCameraImage(CameraImage image) async {
    final Uint8List input = _convertCameraImageToUint8List(image);
    final img.Image? decodedImage = img.decodeImage(input);
    if (decodedImage == null) return;

    final inputImage = _preprocessImage(decodedImage, 128, 128);
    List<List<double>> output = List.generate(1, (_) => List.filled(896 * 16, 0.0));

    _interpreter.run(inputImage, output);
    setState(() {
      _faceBoxes = _getBoundingBoxes(output[0]);
      _numFaces = _faceBoxes.length;
    });
  }

  Uint8List _convertCameraImageToUint8List(CameraImage image) {
    final BytesBuilder buffer = BytesBuilder();
    for (var plane in image.planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  Uint8List _preprocessImage(img.Image image, int width, int height) {
    img.Image resized = img.copyResize(image, width: width, height: height);
    return Uint8List.fromList(resized.getBytes(format: img.Format.rgb));
  }

  List<Rect> _getBoundingBoxes(List<double> output) {
    List<Rect> boxes = [];
    for (int i = 0; i < 896; i++) {
      double score = output[i * 16 + 4];
      if (score > 0.75) {
        double xMin = output[i * 16];
        double yMin = output[i * 16 + 1];
        double width = output[i * 16 + 2];
        double height = output[i * 16 + 3];
        boxes.add(Rect.fromLTWH(xMin, yMin, width, height));
      }
    }
    return boxes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Rostros'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Número de rostros detectados: $_numFaces',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : CameraPreview(_controller!),
                CustomPaint(
                  painter: _BoundingBoxPainter(_faceBoxes),
                  child: Container(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Usar Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.image),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;

  _BoundingBoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var box in boxes) {
      final adjustedBox = Rect.fromLTRB(
        box.left * size.width,
        box.top * size.height,
        box.right * size.width,
        box.bottom * size.height,
      );
      canvas.drawRect(adjustedBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
