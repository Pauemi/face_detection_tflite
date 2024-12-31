import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'utils/face_detection_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  Uint8List? _imageBytes; // Imagen seleccionada
  String _detectionResult = 'Sin detección'; // Mensaje de detección

  @override
  void initState() {
    super.initState();
    _initializeModel(); // Inicializar el modelo al iniciar la pantalla
  }

  // Inicializar el modelo de detección
  Future<void> _initializeModel() async {
    await _faceDetectionService.initializeModel();
    setState(() {
      _detectionResult = 'Modelo cargado con éxito';
    });
  }

  // Capturar una imagen desde la cámara
  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null) {
    final imageBytes = await pickedFile.readAsBytes(); // Leer los bytes de la imagen
    setState(() {
      _imageBytes = imageBytes; // Actualizar el estado
    });
    _detectFaces(); // Ejecutar la detección facial
  }
}


  // Detectar rostros en la imagen seleccionada
  Future<void> _detectFaces() async {
    if (_imageBytes != null) {
      final inputImage = _faceDetectionService.preprocessImage(_imageBytes!);
      final result = _faceDetectionService.runModel(inputImage);

      setState(() {
        _detectionResult = 'Rostros detectados: ${result.length}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección Facial'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageBytes != null)
            Image.memory(
              _imageBytes!,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            )
          else
            const Text('No se ha seleccionado ninguna imagen.'),
          const SizedBox(height: 16),
          Text(
            _detectionResult,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Capturar Imagen'),
          ),
        ],
      ),
    );
  }
}
