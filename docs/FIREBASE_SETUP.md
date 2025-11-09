Firebase setup instructions

This project was prepared to integrate Firebase, Google Sign-In and Firestore. I added code and Gradle changes, and implemented the authentication flow. To complete configuration you must run the FlutterFire CLI locally and add platform configuration files.

1) Install FlutterFire CLI

```powershell
# Once only
dart pub global activate flutterfire_cli
# Ensure the pub cache bin directory is on your PATH, e.g. add
# C:\Users\<you>\AppData\Local\Pub\Cache\bin to PATH
```

2) Run FlutterFire configure

From the project root (D:\NutriCare):

```powershell
flutterfire configure
```

- The CLI will ask you to select the Firebase project (choose the one you created in the Firebase Console), and the platforms to configure (android, ios, web).
- This generates `lib/firebase_options.dart` and updates web/index.html if you select web.

3) Android: add google-services.json

- Download `google-services.json` from the Firebase Console (Project Settings → General → Your apps → Android) and place it at `android/app/google-services.json`.
- The Gradle files were updated to include the Google services plugin (Kotlin DSL). If your project uses Groovy DSL instead, please adapt accordingly.

4) iOS: add GoogleService-Info.plist

- Download `GoogleService-Info.plist` from the Firebase Console and add it to `ios/Runner/` in Xcode (do not just copy the file; add it to the Runner target).

5) Web

- If you selected web during `flutterfire configure`, the CLI will add the required config to web/index.html and generate firebase_options.dart.

6) Run the app

```powershell
flutter pub get
flutter run -d chrome
```

Troubleshooting

- If `flutterfire` is not found after activating, ensure the Pub cache bin folder (`C:\Users\<you>\AppData\Local\Pub\Cache\bin`) is on your PATH.
- If you prefer, you can run the CLI via:

```powershell
dart pub global run flutterfire_cli configure
```

Once `lib/firebase_options.dart` is generated and `google-services.json` / `GoogleService-Info.plist` are in place, the app will initialize Firebase automatically on startup.

If you want I can attempt to run `flutterfire configure` here, but it requires developer authentication and access to your Firebase project; it's best to run it locally on your machine where you can authenticate.
