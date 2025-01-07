import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class OptionsFace {
  final int numClasses;
  final int numBoxes;
  final int numCoords;
  final int keypointCoordOffset;
  final List<int> ignoreClasses;
  final double scoreClippingThresh;
  final double minScoreThresh;
  final int numKeypoints;
  final int numValuesPerKeypoint;
  final int boxCoordOffset;
  final double xScale;
  final double yScale;
  final double wScale;
  final double hScale;
  final bool applyExponentialOnBoxSize;
  final bool reverseOutputOrder;
  final bool sigmoidScore;
  final bool flipVertically;

  OptionsFace({
    required this.numClasses,
    required this.numBoxes,
    required this.numCoords,
    required this.keypointCoordOffset,
    required this.ignoreClasses,
    required this.scoreClippingThresh,
    required this.minScoreThresh,
    required this.numKeypoints,
    required this.numValuesPerKeypoint,
    required this.boxCoordOffset,
    required this.xScale,
    required this.yScale,
    required this.wScale,
    required this.hScale,
    required this.applyExponentialOnBoxSize,
    required this.reverseOutputOrder,
    required this.sigmoidScore,
    required this.flipVertically,
  });
}

class Detection {
  final double score;
  final double xMin;
  final double yMin;
  final double width;
  final double height;

  Detection(this.score, this.xMin, this.yMin, this.width, this.height);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _displayedImageBytes;
  List<Detection> _detections = [];
  int _numFaces = 0;
  late Interpreter _interpreter;
  late OptionsFace options;

  @override
  void initState() {
    super.initState();
    _loadModel();
    options = OptionsFace(
      numClasses: 1,
      numBoxes: 896,
      numCoords: 16,
      keypointCoordOffset: 4,
      ignoreClasses: [],
      scoreClippingThresh: 100.0,
      minScoreThresh: 0.75,
      numKeypoints: 6,
      numValuesPerKeypoint: 2,
      boxCoordOffset: 0,
      xScale: 128,
      yScale: 128,
      hScale: 128,
      wScale: 128,
      applyExponentialOnBoxSize: false,
      reverseOutputOrder: true,
      sigmoidScore: true,
      flipVertically: false,
    );
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/blaze_face_short_range.tflite');
      _interpreter.allocateTensors();
      debugPrint('Modelo cargado correctamente.');
    } catch (e) {
      debugPrint('Error al cargar el modelo: $e');
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final XFile? imageFile = await _picker.pickImage(source: source);
      if (imageFile != null) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final img.Image? decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          _displayedImageBytes = Uint8List.fromList(img.encodePng(decodedImage));
          await _processImage(decodedImage);
          setState(() {});
        }
      }
      debugPrint('Imagen cargada correctamente.');
    } catch (e) {
      debugPrint('Error al cargar la imagen: $e');
    }
  }

  Future<void> _processImage(img.Image image) async {
    try {
      final img.Image resizedImage = img.copyResize(image, width: 128, height: 128);
      final Float32List inputImage = Float32List(1 * 128 * 128 * 3);
      int index = 0;
      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputImage[index++] = (img.getRed(pixel) / 127.5) - 1.0;
          inputImage[index++] = (img.getGreen(pixel) / 127.5) - 1.0;
          inputImage[index++] = (img.getBlue(pixel) / 127.5) - 1.0;
        }
      }

      final output = List.filled(896 * 16, 0.0).reshape([1, 896, 16]);

      _interpreter.run(inputImage.reshape([1, 128, 128, 3]), output);

      _detections = _getBoundingBoxes(output[0]);
      setState(() {
        _numFaces = _detections.length;
      });
      debugPrint('Imagen procesada correctamente.');
    } catch (e) {
      debugPrint('Error al procesar la imagen: $e');
    }
  }

  List<Detection> _getBoundingBoxes(List<List<double>> output) {
    List<Detection> detections = [];
    for (int i = 0; i < options.numBoxes; i++) {
      final double score = output[i][4];
      if (score > options.minScoreThresh) {
        double xMin = output[i][0];
        double yMin = output[i][1];
        double width = output[i][2];
        double height = output[i][3];
        detections.add(Detection(score, xMin, yMin, width, height));
      }
    }
    return detections;
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
            child: _displayedImageBytes == null
                ? const Text(
                    'Selecciona una imagen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : Text(
                    'Número de rostros detectados: $_numFaces',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
          Expanded(
            child: Center(
              child: _displayedImageBytes == null
                  ? const Icon(Icons.image, size: 200, color: Colors.grey)
                  : Stack(
                      children: [
                        Image.memory(_displayedImageBytes!),
                        CustomPaint(
                          painter: _BoundingBoxPainter(_detections, imageSize: 128),
                          child: Container(),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.gallery),
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
  final List<Detection> detections;
  final int imageSize;

  _BoundingBoxPainter(this.detections, {required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final detection in detections) {
      final adjustedBox = Rect.fromLTWH(
        detection.xMin * size.width / imageSize,
        detection.yMin * size.height / imageSize,
        detection.width * size.width / imageSize,
        detection.height * size.height / imageSize,
      );
      canvas.drawRect(adjustedBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
