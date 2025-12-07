
import '../workers/hydration_worker.dart';
import 'package:flutter/foundation.dart';

class BackgroundInitializer {
  static Future<void> init() async {
    // Only run background worker on Android/iOS, not web
    if (!kIsWeb) {
      await HydrationWorker.register();
    }
  }
}
