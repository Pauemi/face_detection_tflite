import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Uso directo de tflite_flutter
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  late tfl.Interpreter _interpreter;   // Intérprete de tflite_flutter
  bool _isInterpreterReady = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // 1) Cargar modelo con tflite_flutter
  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset(
        'blaze_face_short_range.tflite',
      );
      setState(() {
        _isInterpreterReady = true;
      });
      debugPrint('Modelo cargado correctamente');
    } catch (e) {
      debugPrint('Error al cargar modelo: $e');
    }
  }

  // 2) Seleccionar imagen (galería o cámara)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      // Aquí podrías llamar a tu método de detección
      // _runFaceDetection(_image!);
    }
  }

  // 3) Ejecutar la inferencia
  Future<void> _runFaceDetection(File image) async {
    if (!_isInterpreterReady) return;

    // a) Cargar la imagen en formato bytes
    // b) Preprocesar la imagen (resize, normalizar, etc.)
    // c) Invocar _interpreter.run(input, output)
    // d) Parsear la salida (coordenadas, puntuaciones, etc.)

    // Ejemplo (muy simplificado, dependerá de cómo blaze_face_short_range.tflite
    // espere la entrada):
    // Suponiendo que reciba [1, height, width, 3], con un tamaño de 128x128

    // 1. Leer la imagen con la librería 'image' (si lo deseas) y hacer resize:
    //    final rawImage = img.decodeImage(File(image.path).readAsBytesSync())!;
    //    final resized = img.copyResize(rawImage, width: 128, height: 128);
    //    final inputImage = _imageToByteListFloat32(resized, 128);

    // 2. Crear el output según la forma que devuelva tu modelo
    //    Por ejemplo: List<dynamic> output = List.filled(1 * NUM_BOXES * 4, 0).reshape([1, NUM_BOXES, 4]);

    // 3. Llamar a la inferencia
    //    _interpreter.run(inputImage, output);

    // 4. Interpretar output y dibujar bounding boxes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección Facial con tflite_flutter'),
      ),
      body: Center(
        child: _image == null
            ? const Text('No hay imagen')
            : Image.file(_image!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'gallery',
            child: const Icon(Icons.photo),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}