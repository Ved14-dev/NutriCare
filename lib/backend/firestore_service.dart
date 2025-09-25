import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
    static Future<void> sendMockFoodData() async {
        await FirebaseFirestore.instance.collection('aggregated_food_data').add({
            'food': 'rice',
            'calories': 200,
            'location': 'Kochi',
            'timestamp': DateTime.now(),
        });
    }
}
