import '../services/hydration_json_service.dart';
import '../services/health_recommendation_service.dart';

class ChatbotDataService {
  final HydrationJsonService _hydrationJsonService = HydrationJsonService();
  final HealthRecommendationService _recommendationService = HealthRecommendationService();

  Future<Map<String, dynamic>> getUserDataForChatbot(String userId) async {
    final hydrationLogs = await _hydrationJsonService.getHydrationLogsAsJson(userId);
    final recommendations = await _recommendationService.getUserRecommendations(userId);
    return {
      'hydration_logs': hydrationLogs,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
    };
  }
}
