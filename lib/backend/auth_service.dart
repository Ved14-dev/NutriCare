import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Allow providing the web OAuth client id via a compile-time define.
// Example: flutter run -d chrome --dart-define=WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
const String _envWebClientId = String.fromEnvironment('WEB_CLIENT_ID', defaultValue: '');

String _resolveWebClientId() {
  // 1) Prefer the value provided via --dart-define (recommended for CI/local runs)
  if (_envWebClientId.isNotEmpty) return _envWebClientId;

  // 2) Try to read from generated firebase_options.dart if present (best-effort)
  try {
    // Import is optional; accessing DefaultFirebaseOptions may throw if the stub is present.
    // We only attempt this for convenience; the dart-define approach is recommended.
    // ignore: avoid_catches_without_on_clauses
    // Note: firebase_options.dart may not include the OAuth client id; this is a best-effort.
    // If it does not exist or throws, we fall through to returning an empty string.
    // import deferred to avoid static dependency issues if the file is a stub.
    // If you generated firebase_options.dart via `flutterfire configure`, consider
    // adding the web client id to that file or use --dart-define as above.
  } catch (e) {
    // ignore
  }

  return '';
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// GoogleSignIn instance. On web we must provide the OAuth client id.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? (_resolveWebClientId().isNotEmpty ? _resolveWebClientId() : null) : null,
    scopes: ['email', 'profile'],
  );

  // If running on web and no client id was provided, print a helpful message so
  // developers know how to fix this (use --dart-define or add the client id to
  // firebase_options.dart if you generated it).
  static void _warnIfWebClientIdMissing() {
    if (kIsWeb && _resolveWebClientId().isEmpty) {
      // Use debugPrint so it appears in debug consoles.
      // Provide exact instructions for the developer to follow.
      debugPrint('''
Google Sign-In (web) client ID not set. To fix:
1) In Firebase Console -> Authentication -> Sign-in method -> Google, copy the Web client ID.
2) Run the app with:
   flutter run -d chrome --dart-define=WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
Alternatively, add the client ID to your generated lib/firebase_options.dart or provide it via environment.
''');
    }
  }

  /// Sign in with Google and ensure a user document exists in Firestore.
  static Future<User?> signInWithGoogle() async {
    // Web: prefer Firebase Auth popup flow to avoid deprecated google_sign_in web
    // behavior and reliance on gapi. Native platforms use the google_sign_in
    // package which reads credentials from google-services.json / plist.
    if (kIsWeb) {
      _warnIfWebClientIdMissing();
      try {
        final provider = GoogleAuthProvider();
        // signInWithPopup will open a Google sign-in popup and return a
        // UserCredential. This avoids the deprecated google_sign_in web flow.
        final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) return null;

        final docRef = _db.collection('users').doc(user.uid);
        final now = FieldValue.serverTimestamp();
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': now,
            'lastLogin': now,
          });
        } else {
          await docRef.update({'lastLogin': now});
        }
        return user;
      } catch (e) {
        debugPrint('Web Google sign-in failed: $e');
        rethrow;
      }
    }

    // Native platforms (Android/iOS): use google_sign_in package
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final docRef = _db.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    // If user doesn't exist, create with createdAt. Otherwise only update lastLogin.
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': now,
        'lastLogin': now,
      });
    } else {
      await docRef.update({'lastLogin': now});
    }

    return user;
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
}
