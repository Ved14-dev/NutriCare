<#
  fix_and_run_android.ps1

  Robust helper script for Windows PowerShell (5.1+) to prepare and run the app on an
  Android emulator. This script is intentionally simple and defensive in structure so
  it avoids parser and nested-block issues on older PowerShell versions.

  Behavior (best-effort):
  - Clear local build caches that commonly cause Kotlin/Gradle incremental errors
  - Try to install Android SDK components (sdkmanager required and ANDROID_SDK_ROOT set)
  - Try to create a Google Play AVD (API 36 x86_64) if avdmanager present
  - Try to start the AVD/emulator if none is running
  - Create debug keystore if missing (requires keytool in PATH)
  - Run flutter clean, pub get, analyze and then flutter run -d emulator

  Usage:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    .\scripts\fix_and_run_android.ps1

#>

Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Project root: $projectRoot"

# Stop early on unhandled errors
$ErrorActionPreference = 'Stop'

function CommandExists([string]$name) {
  return (Get-Command -Name $name -ErrorAction SilentlyContinue) -ne $null
}

# Detect SDK location
$androidSdk = $env:ANDROID_SDK_ROOT
if (-not $androidSdk -or $androidSdk -eq '') { $androidSdk = $env:ANDROID_HOME }
if (-not $androidSdk -or $androidSdk -eq '') {
  Write-Warning "ANDROID_SDK_ROOT not set. SDK auto-install skipped."
} else { Write-Host "Detected Android SDK at: $androidSdk" }

# Clean common build cache directories (save developer time when incremental caches are broken)
$pathsToRemove = @(
  Join-Path $projectRoot 'build',
  Join-Path $projectRoot 'android\build',
  Join-Path $projectRoot 'android\app\build',
  Join-Path $projectRoot '.gradle'
)
foreach ($p in $pathsToRemove) {
  if (Test-Path $p) {
    Write-Host "Removing: $p"
    Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Clear plugin caches inside top-level build directory
if (Test-Path (Join-Path $projectRoot 'build')) {
  Get-ChildItem -Path (Join-Path $projectRoot 'build') -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    try { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch { }
  }
}

# If sdkmanager exists, try to install required platform / build-tools for API 36
if ((-not [string]::IsNullOrEmpty($androidSdk)) -and (CommandExists "sdkmanager")) {
    sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "cmake;3.22.1" "ndk;25.3.1" 2>$null
    Write-Host "Attempting to accept SDK licenses (interactive if required)"
    & flutter doctor --android-licenses
} else {
  Write-Host "Skipping SDK auto-install (sdkmanager not found or ANDROID_SDK_ROOT unset)."
}

# Attempt to ensure a Google Play AVD for API 36 exists and start it if no emulator is running.
$avdName = 'NutriCare_AVD_api36'
$needCreateAVD = $true
if (CommandExists emulator) {
  try {
    $avds = (& emulator -list-avds 2>$null | Out-String).Trim()
    if ($avds -and ($avds -match [regex]::Escape($avdName))) { $needCreateAVD = $false }
  } catch { }
} else { Write-Host "emulator command not available; skipping AVDS check" }

if ($needCreateAVD -and (CommandExists "avdmanager") -and (CommandExists "sdkmanager")) {
  Write-Host "Creating Google Play system image and AVD ($avdName) for API 36 (if not present)"
  & sdkmanager "system-images;android-36;google_apis_playstore;x86_64" 2>$null
  try {
    & avdmanager create avd -n $avdName -k "system-images;android-36;google_apis_playstore;x86_64" --force -d pixel_6 2>$null
    Write-Host "AVD $avdName created or already existed"
  } catch { Write-Warning "Could not create AVD $avdName (create manually with Android Studio if needed): $_" }
} else {
  if ($needCreateAVD) { Write-Warning "Cannot create AVD: avdmanager or sdkmanager not available" }
  else { Write-Host "AVD $avdName already exists" }
}
# If no emulator is running, try to start our AVD (best-effort)
$r = (& flutter devices --machine 2>$null | Out-String)
if (-not ($r -match 'device')) {
  if (CommandExists emulator) {
    Write-Host "Starting emulator: $avdName (the emulator process will run separately)"
    Start-Process -FilePath emulator -ArgumentList '-avd', $avdName -WindowStyle Minimized -NoNewWindow -ErrorAction SilentlyContinue | Out-Null
    Write-Host "Waiting for emulator to initialize (this may take 20-40s)..."
    Start-Sleep -Seconds 20
  } else {
    Write-Warning "No emulator runtime found; please start one from Android Studio or add emulator to PATH"
  }
} else {
  Write-Host "An Android device/emulator appears to be connected — skipping emulator start"
}

# Ensure Flutter packages and a clean build
Write-Host "Running flutter clean + pub get"
flutter clean
flutter pub get

# Create debug keystore if missing so you can print SHA fingerprints easily
$debugKeystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
if (-not (Test-Path $debugKeystore)) {
  if (CommandExists keytool) {
    Write-Host "Creating debug keystore at $debugKeystore"
    try {
      & keytool -genkeypair -alias androiddebugkey -keypass android -storepass android -dname "CN=Android Debug,O=Android,C=US" -keystore $debugKeystore -storetype JKS -keyalg RSA -keysize 2048
      Write-Host "Created debug keystore"
    } catch { Write-Warning "keytool failed to create debug keystore: $_" }
  } else { Write-Warning "keytool is not available in PATH; cannot create debug keystore automatically" }
} else { Write-Host "Debug keystore already exists: $debugKeystore" }

# Quick static checks
Write-Host "Running flutter analyze"
flutter analyze

# Launch the app on the first emulator target
Write-Host "Attempting to run the app on an Android emulator (flutter run -d emulator)"
flutter run -d emulator

Write-Host "Finished helper script — if Google Sign-In still fails, add SHA-1 and SHA-256 from the debug keystore to the Firebase Console and re-download google-services.json"
<#
  fix_and_run_android.ps1

  This helper script attempts to make this Flutter project runnable on an Android emulator
  by performing safe local fixes, clearing stale caches, and running a clean build.

  It is intentionally idempotent and cautious — some commands require the Android SDK tools
  to be installed and available in PATH. The script tries to use sdkmanager if available.

  USAGE (PowerShell):
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    .\scripts\fix_and_run_android.ps1

#>

Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Project root: $projectRoot"

# Try to detect ANDROID_SDK_ROOT (flutter doctor would normally manage this)
$androidSdk = $env:ANDROID_SDK_ROOT
if (-not $androidSdk -or $androidSdk -eq '') {
  $androidSdk = $env:ANDROID_HOME
}
if (-not $androidSdk -or $androidSdk -eq '') {
  Write-Warning "ANDROID_SDK_ROOT is not set. The script will still attempt to run Flutter commands but cannot auto-install SDK components."
} else {
  Write-Host "Detected Android SDK at: $androidSdk"
}

# Stop on first error
$ErrorActionPreference = 'Stop'

# Remove build caches that often cause Kotlin/Gradle incremental issues
$pathsToRemove = @("$projectRoot\build", "$projectRoot\android\build", "$projectRoot\android\app\build", "$projectRoot\.gradle")
foreach ($p in $pathsToRemove) {
  if (Test-Path $p) {
    Write-Host "Removing: $p"
    Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Remove problematic plugin caches created on other drives (where kotlin incremental caches can confuse the compiler)
Write-Host "Cleaning plugin build caches in ./build/* where present"
Get-ChildItem -Path "$projectRoot\build" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  try { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch { }
}

# Try to auto-install common required SDK components if sdkmanager exists
if ($androidSdk -and (Get-Command -Name sdkmanager -ErrorAction SilentlyContinue)) {
  Write-Host "sdkmanager found. Ensuring key Android packages are installed (platforms; build-tools; cmake)"
  & sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "cmake;3.22.1" "ndk;25.3.1" 2>$null
  Write-Host "Attempting to accept Android SDK licenses (if available)."
  & flutter doctor --android-licenses
} else {
  Write-Warning "sdkmanager not found or ANDROID_SDK_ROOT unset — you may need to install Android SDK packages manually via Android Studio."
}

# Try to auto-create and start a Google-Play AVD (useful for Google Sign-In) if avdmanager/emulator exist
$avdName = "NutriCare_AVD_api36"
$avdExists = $false
try {
  $emulatorList = & emulator -list-avds 2>$null
  if ($LASTEXITCODE -eq 0 -and $emulatorList) {
    if ($emulatorList -match [regex]::Escape($avdName)) { $avdExists = $true }
  }
} catch { }

if (-not $avdExists) {
  $avdmanagerCmd = Get-Command avdmanager -ErrorAction SilentlyContinue
  if ($null -ne $avdmanagerCmd -and (Get-Command sdkmanager -ErrorAction SilentlyContinue)) {
    Write-Host "AVD $avdName not found — attempting to install system image and create one (API 36, Google Play)."
    & sdkmanager "system-images;android-36;google_apis_playstore;x86_64" 2>$null
    # Create AVD using avdmanager. The device id 'pixel_6' is commonly available; if not, avdmanager will list alternatives
    try {
      & avdmanager create avd -n $avdName -k "system-images;android-36;google_apis_playstore;x86_64" --force -d pixel_6 2>$null
      Write-Host "Created AVD $avdName"
    } catch {
      Write-Warning "Failed to create AVD $avdName. You may need to create one manually with Android Studio or avdmanager."
    }
  } else {
    Write-Host "avdmanager or sdkmanager not available — cannot auto-create an AVD."
  }
}

# Start emulator if not already running
try {
  $running = & flutter devices --machine | Out-String
  if ($running -notmatch 'device') {
    # Start emulator in background if available
    Write-Host "No running Android emulator detected. Attempting to start $avdName (this may block)."
    if (Get-Command -Name emulator -ErrorAction SilentlyContinue) {
      Start-Process -FilePath emulator -ArgumentList "-avd", $avdName -NoNewWindow -WindowStyle Hidden
      Write-Host "Started emulator $avdName. Wait a few seconds and the script will try to run the app."
      Start-Sleep -Seconds 8
    } else {
      Write-Warning "emulator command not available — start an AVD via Android Studio or set emulator in PATH."
    }
  } else {
    Write-Host "Android emulator already running."
  }
} catch { Write-Warning "Unable to detect or start emulator: $_" }

# Ensure Flutter packages and a clean build
Write-Host "Running flutter clean + pub get"
flutter clean
flutter pub get

# If the debug keystore is missing, try to create it so developers can get SHA-1 fingerprints
$debugKeystorePath = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (-not (Test-Path $debugKeystorePath)) {
  Write-Host "debug.keystore not found at $debugKeystorePath. Attempting to create one using keytool (if available)..."
  $keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
  if ($null -ne $keytoolCmd) {
    try {
      & keytool -genkeypair -alias androiddebugkey -keypass android -storepass android -dname "CN=Android Debug,O=Android,C=US" -keystore $debugKeystorePath -storetype JKS -keyalg RSA -keysize 2048
      Write-Host "Created debug keystore at $debugKeystorePath"
    } catch {
      Write-Warning "keytool exists but failed to create debug keystore: $_";
    }
  } else {
    Write-Warning "keytool not found in PATH; cannot auto-create debug keystore. Install JDK and make keytool available in PATH or create the keystore manually."
  }
}

# Optional: run analyzer to show if there are remaining warnings/errors
Write-Host "Running flutter analyze..."
flutter analyze

# Run on the default Android emulator device (only if emulator exists)
Write-Host "Starting the app on an available Android emulator (if one is running)..."
flutter run -d emulator

$finalMsg = @"
Script finished. If the app fails to start in the emulator, ensure:
  - You launched an AVD with Google Play (to support Google Sign-In) and added SHA-1/SHA-256 to Firebase
  - android/app/google-services.json is present and correct
  - ANDROID_SDK_ROOT is configured and sdkmanager path is available
"@
Write-Host $finalMsg
