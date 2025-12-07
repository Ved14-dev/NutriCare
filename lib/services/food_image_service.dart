import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../secrets.dart';

class FoodImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickCameraImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return null;
    return await file.readAsBytes();
  }

  static Future<Uint8List?> pickGalleryImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return null;
    return await file.readAsBytes();
  }

  static Future<List<Map<String, dynamic>>> analyzeFoodImageWithGemini(Uint8List imageBytes) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppSecrets.geminiApiKey,
    );
    final prompt = '''Analyze the food in this image and return a JSON array of foods with the following structure:
{
  "foods": [
    {
      "name": "",
      "calories": number,
      "protein_g": number,
      "carbs_g": number,
      "fat_g": number,
      "serving_size": ""
    }
  ]
}
Return only the JSON.''';
    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ]);
    final response = await model.generateContent([content]);
    final text = response.text ?? '';
    try {
      final jsonMap = json.decode(text);
      if (jsonMap is Map && jsonMap['foods'] is List) {
        return List<Map<String, dynamic>>.from(jsonMap['foods']);
      }
    } catch (e) {
      debugPrint('Gemini JSON parse error: $e\n$text');
    }
    throw Exception('Could not extract food data from image.');
  }

  static Future<void> saveFoodLogToFirestore(List<Map<String, dynamic>> foods) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    final totalCalories = foods.fold<int>(0, (sum, f) {
      final cal = f['calories'];
      int caloriesInt;
      if (cal is int) {
        caloriesInt = cal;
      } else if (cal is String) {
        caloriesInt = int.tryParse(cal) ?? 0;
      } else if (cal is double) {
        caloriesInt = cal.round();
      } else {
        caloriesInt = 0;
      }
      return sum + caloriesInt;
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .add({
      'foods': foods,
      'totalCalories': totalCalories,
      'timestamp': Timestamp.now(),
      'source': 'image',
    });
  }
}
