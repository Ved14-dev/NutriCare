import '../data/hydration_repository.dart';

class HydrationService {
  final _repo = HydrationRepository();

  Future<void> trackHydrationInBackground() async {
    // Fetch hydration data, update Firestore, handle analytics, streaks, etc.
    await _repo.logHydrationEvent();
  }
}
