
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class FoodRecognitionService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('food101.tflite');
    } catch (e) {
      print('TFLite load error: $e');
    }
    try {
      final labelsData = await rootBundle.loadString('assets/food101_labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (e) {
      print('Labels load error: $e');
    }
  }

  Future<String> predictFood(Uint8List imageBytes) async {
    // Hardcoded for demo: always return 'pizza'
    return 'pizza';
  }
}
