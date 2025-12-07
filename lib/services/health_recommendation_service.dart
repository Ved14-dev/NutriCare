import '../data/health_recommendation_repository.dart';
import '../domain/health_recommendation.dart';

class HealthRecommendationService {
  final HealthRecommendationRepository _repo = HealthRecommendationRepository();

  Future<void> generateAndStoreRecommendation(String userId) async {
    // TODO: Analyze hydration/food logs, user profile, and generate recommendation
    final rec = HealthRecommendation(
      id: '',
      userId: userId,
      type: 'hydration',
      message: 'Drink more water today!',
      createdAt: DateTime.now(),
    );
    await _repo.addRecommendation(rec);
  }

  Future<List<HealthRecommendation>> getUserRecommendations(String userId) async {
    return _repo.getRecommendations(userId);
  }
}
