import 'dart:typed_data';

import 'package:image/src/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart' as helper;
import 'package:tflite_flutter_plus/src/bindings/types.dart';

class FaceDetectionService {
  late tflite.Interpreter _interpreter;

  // Inicializar el modelo
  Future<void> initializeModel() async {
    _interpreter = await tflite.Interpreter.fromAsset('assets/models/blazeface_short_range.tflite');
  }

  // Preprocesar la imagen para que sea compatible con el modelo
  helper.TensorImage preprocessImage(Uint8List imageBytes) {
    // Configurar el procesador de imágenes
    final imageProcessor = helper.ImageProcessorBuilder()
        .add(helper.ResizeOp(128, 128, helper.ResizeMethod.bilinear)) // Cambiar el tamaño a 128x128
        .add(helper.NormalizeOp(0, 255)) // Normalizar los valores
        .build();

    // Crear un TensorImage
    helper.TensorImage tensorImage = helper.TensorImage(tflite.TfLiteType.kTfLiteFloat32 as TfLiteType);

    // Cargar los bytes en el TensorImage
    tensorImage.loadImage(imageBytes as Image);

    // Procesar la imagen
    tensorImage = imageProcessor.process(tensorImage);

    return tensorImage;
  }

  // Ejecutar el modelo con la imagen procesada
  List<dynamic> runModel(helper.TensorImage inputImage) {
    // Configuración de la salida
    final outputBuffer = helper.TensorBuffer.createFixedSize([1, 896], tflite.TfLiteType.kTfLiteFloat32 as TfLiteType);

    // Ejecutar el modelo
    _interpreter.run(inputImage.buffer, outputBuffer.buffer);

    // Retornar los resultados
    return outputBuffer.getDoubleList();
  }
}
