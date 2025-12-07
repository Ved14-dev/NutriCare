import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/hydration_service.dart';

// Entry point for background isolate
void hydrationWorkerCallback() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await HydrationService().trackHydrationInBackground();
  } catch (e) {
    // Handle error, retry, or log
  }
}

class HydrationWorker {
  static const String taskName = 'hydrationWorkerTask';

  static Future<void> register() async {
    if (kIsWeb) return; // Do not register on web
    await Workmanager().initialize(
      hydrationWorkerDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(hours: 2),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

void hydrationWorkerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    hydrationWorkerCallback();
    return Future.value(true);
  });
}
