NutriCare MVP

Offline-first calorie tracking app for everyday nutrition awareness.

*******************************************************************************************
// cd "C:\Users\VEDANT\AppData\Local\Android\Sdk\emulator"
// .\emulator.exe -avd Medium_Phone_API_36.1
// flutter clean
// flutter pub get
// flutter run -d emulator-5554
*******************************************************************************************
// flutter clean
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
*******************************************************************************************

How to Run:
1. Install Flutter SDK.
2. Clone this repo.
3. Run flutter pub get.
4. Set up Firebase (see below).
5. Run flutter run.

Features Demonstrated:
- Simple, visual-first UI (Home, Food Log, Chat, QR).
- Offline calorie log storage (encrypted SQLite).
- AI nutrition chatbot (pre-programmed responses, TFLite stub).
- Nutritionist access via QR code (one-time token).
- Backend: Firebase Firestore (users, aggregated_food_data).

