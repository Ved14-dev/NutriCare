NutriCare MVP

Offline-first calorie tracking app for everyday nutrition awareness.

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

Firebase Setup:
- Create a Firebase project.
- Add Android/iOS apps.
- Enable Authentication and Firestore.
- Download google-services.json/GoogleService-Info.plist and place in respective folders.

Judges: See comments in code for feature explanations.
