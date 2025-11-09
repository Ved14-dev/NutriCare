# NutriCare Firebase Configure Script (PowerShell)
# Purpose: help you run the FlutterFire CLI interactively to generate lib/firebase_options.dart
# Usage: Open PowerShell in the project root (D:\NutriCare) and run: .\scripts\firebase_configure.ps1

# 1) Ensure FlutterFire CLI is installed (one-time)
dart pub global activate flutterfire_cli

# 2) Add pub-cache bin to PATH for this session (so 'flutterfire' is available)
# Safely add the pub-cache bin directory to PATH for this session
$pubCacheBin = [IO.Path]::Combine($env:USERPROFILE, 'AppData', 'Local', 'Pub', 'Cache', 'bin')
$env:PATH += ";$pubCacheBin"

# 3) Login to FlutterFire (this opens a browser for authentication)
# Use the installed flutterfire if available, otherwise run via dart
if (Get-Command flutterfire -ErrorAction SilentlyContinue) {
    Write-Host "Using flutterfire from PATH to login..."
    flutterfire login -q
} else {
    Write-Host "'flutterfire' not found on PATH - running via 'dart pub global run' to login"
    dart pub global run flutterfire_cli login -q
}

# 4) Run configure for your Firebase project. Replace the project id if desired.
$projectId = 'nutricare-1fb2c'
if (Get-Command flutterfire -ErrorAction SilentlyContinue) {
    Write-Host "Running: flutterfire configure --project=$projectId --platforms android,ios,web"
    flutterfire configure --project=$projectId --platforms android,ios,web
} else {
    Write-Host "Running via dart: dart pub global run flutterfire_cli configure --project=$projectId --platforms android,ios,web"
    dart pub global run flutterfire_cli configure --project=$projectId --platforms android,ios,web
}

Write-Host "`n✅ After configuration completes:`n"
Write-Host "  1) If present, verify lib/firebase_options.dart was created."
Write-Host "     - If not: check the CLI output above for errors and paste it into the chat."
Write-Host "  2) Download google-services.json from Firebase Console (Android app) and place it at: android/app/google-services.json"
Write-Host "  3) Download GoogleService-Info.plist and add it to ios/Runner/ in Xcode (add to Runner target)."
Write-Host "  4) Run: flutter pub get; flutter clean; flutter run -d chrome"

Write-Host "Script finished. If any steps failed, copy/paste the CLI output here and I will help debug."