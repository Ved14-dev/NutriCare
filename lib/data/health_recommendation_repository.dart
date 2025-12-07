import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/health_recommendation.dart';

class HealthRecommendationRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addRecommendation(HealthRecommendation rec) async {
    await _firestore.collection('health_recommendations').add(rec.toJson());
  }

  Future<List<HealthRecommendation>> getRecommendations(String userId) async {
    final query = await _firestore
        .collection('health_recommendations')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return query.docs
        .map((doc) => HealthRecommendation.fromJson(doc.data()))
        .toList();
  }
}
