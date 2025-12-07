import 'package:get_it/get_it.dart';
import '../services/hydration_service.dart';
import '../services/hydration_analytics_service.dart';
import '../services/hydration_json_service.dart';
import '../services/health_recommendation_service.dart';
import '../services/notification_service.dart';
import '../services/chatbot_data_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => HydrationService());
  locator.registerLazySingleton(() => HydrationAnalyticsService());
  locator.registerLazySingleton(() => HydrationJsonService());
  locator.registerLazySingleton(() => HealthRecommendationService());
  locator.registerLazySingleton(() => NotificationService());
  locator.registerLazySingleton(() => ChatbotDataService());
}
