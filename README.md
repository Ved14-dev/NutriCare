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

Firebase Setup:
- Create a Firebase project.
- Add Android/iOS apps.
- Enable Authentication and Firestore.
- Download google-services.json/GoogleService-Info.plist and place in respective folders.

Judges: See comments in code for feature explanations.

## Running on Android emulator / device (quick guide)

If you want to run NutriCare on an Android emulator or a real Android device, follow these steps:

1. Make sure the Android SDK, an emulator, and a working device are available in your environment (Android Studio or stand-alone emulator).

2. Add the Android app to your Firebase project and ensure you have a valid `android/app/google-services.json` file in the project. The JSON in this repo is present for development — confirm it matches the Firebase app (package name and project).

3. Add debug SHA fingerprints in the Firebase console for Google Sign-In to work on the emulator:

	- On Windows you can get the debug keystore fingerprint using keytool (part of the JDK):

	  keytool -list -v -keystore "%USERPROFILE%\\.android\\debug.keystore" -alias androiddebugkey -storepass android -keypass android

	- Copy the SHA-1 and SHA-256 values into the Firebase Console -> Project Settings -> Your apps -> Android app -> Add Fingerprint.

4. (Optional) If you add fingerprints / reconfigure the app in the console, re-download the matching `google-services.json` and place it in `android/app/`.

5. Clean and run on the emulator:

	flutter clean; flutter pub get; flutter run -d emulator

Or use the helper script that attempts to clear problematic caches, install common SDK components (if sdkmanager is available), and run the app:

  powershell -ExecutionPolicy RemoteSigned -File .\scripts\fix_and_run_android.ps1

Notes and tips:

- The Android manifest already includes INTERNET and ACCESS_NETWORK_STATE permissions, and Cleartext is enabled for development builds to allow unencrypted http calls in the emulator. Remove cleartext before shipping to production.
- MultiDex is enabled in the Android module and MainActivity now installs it at runtime so the app is less likely to hit the 64K dex method limit on older/emulator devices.
- If you use Google Sign-In, make sure the Android package id in Firebase matches the `applicationId` in `android/app/build.gradle.kts`.
- Avoid committing secrets (Gemini API key). For secure usage prefer passing keys via `--dart-define`, Android native build configs, or storing them outside source control and reading them on startup (for debug, a local uncommitted config file is fine).

Troubleshooting tips:

- If Gradle/Kotlin incremental compile errors show paths on different drives ("different roots") — run the helper script above to clear caches and disable problematic incremental caches automatically.
- If Google Sign-In fails, add SHA-1 and SHA-256 of your debug keystore to Firebase Console and re-download `google-services.json`.

# Gemini API Key Setup

To enable the Gemini AI chatbot, you must create a file at `lib/secrets.dart` with your API key:

```
class AppSecrets {
  static const String geminiApiKey = "YOUR_GEMINI_API_KEY";
}
```

- This file is ignored by git and will not be committed.
- The app will always have the key bundled and work every time you open the APK or run the app.
- If you change the key, rebuild the app.
