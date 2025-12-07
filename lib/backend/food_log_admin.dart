import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogAdmin {
  /// Deletes all food log history for all users in Firestore.
  static Future<void> deleteAllFoodLogs() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    for (final userDoc in users.docs) {
      final foodLogs = await userDoc.reference.collection('food_logs').get();
      for (final log in foodLogs.docs) {
        await log.reference.delete();
      }
    }
  }
}
