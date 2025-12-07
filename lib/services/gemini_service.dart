import 'dart:convert';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:NutriCare/secrets.dart';

class GeminiService {
    static Future<String> getPersonalizedPlan(List<Map<String, dynamic>> foodEntries) async {
      try {
        final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: AppSecrets.geminiApiKey);
        final prompt = '''You are a nutrition and fitness expert. Based on the following food log entries, recommend a personalized meal plan and fitness goals for the user. Consider their nutritional needs, variety, and balance. Return your recommendations in clear, readable text.\n\nFood Log Entries:\n${jsonEncode(foodEntries)}\n\nRecommendations:''';
        final response = await model.generateContent([
          Content.text(prompt),
        ]);
        return response.text ?? 'No recommendations available.';
      } catch (e, stack) {
        print('Gemini error (getPersonalizedPlan): $e');
        print(stack);
        Fluttertoast.showToast(msg: 'Error generating plan: $e');
        return 'Error generating recommendations.';
      }
    }
  static Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash-vision', apiKey: AppSecrets.geminiApiKey);
      final prompt = buildGeminiFoodPrompt();
      
      final response = await model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', imageBytes),
      ]);
      final text = response.text ?? '';
      
      // Remove markdown code blocks if present
      String cleanText = text.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
      
      // Try to extract JSON object (handles nested braces)
      final jsonMatch = RegExp(r'\{(?:[^{}]|\{[^{}]*\})*\}').firstMatch(cleanText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        try {
          final parsed = jsonDecode(jsonString);
          return parsed;
        } catch (jsonErr, jsonStack) {
          print('Gemini error (analyzeFoodImage JSON decode): $jsonErr');
          print(jsonStack);
          Fluttertoast.showToast(msg: 'Error decoding Gemini response: $jsonErr');
          return {'error': 'Error decoding Gemini response.'};
        }
      }
      return {'error': 'No valid JSON found in Gemini response.'};
    } catch (e, stack) {
      print('Gemini error (analyzeFoodImage): $e');
      print(stack);
      Fluttertoast.showToast(msg: 'Error analyzing food image: $e');
      return {'error': 'Error analyzing food image.'};
    }
  }
      // (Removed duplicate/old error handling block)
    }
  String buildGeminiFoodPrompt() {
    return '''Analyze the food in this image and return ONLY a valid JSON object with this exact schema (no markdown, no extra text):
{
  "food_name": "string",
  "quantity": "string",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0,
  "confidence": 0.0,
  "notes": "string"
}
Provide realistic nutritional values. Return ONLY the JSON object, nothing else.''';
  }
