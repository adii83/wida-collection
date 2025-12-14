import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration placeholder generated for manual setups.
///
/// Replace the placeholder values with the actual configuration from
/// `google-services.json` / `GoogleService-Info.plist` or by running
/// `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'Unsupported platform for Firebase initialisation',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgkBlMn1HCTI3S3JGDMzqUHkjceNnyRFM',
    appId: '1:398578610862:android:25f1e5bce0081d332a733f',
    messagingSenderId: '398578610862',
    projectId: 'wida-collection',
    storageBucket: 'wida-collection.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeib5ylFYdgv3HMqYl02GHJRZT5ekyV68',
    appId: '1:398578610862:ios:1f9c6e0f8df8fb6f2a733f',
    messagingSenderId: '398578610862',
    projectId: 'wida-collection',
    storageBucket: 'wida-collection.firebasestorage.app',
    iosBundleId: 'com.example.windaCollection',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_MACOS_API_KEY',
    appId: 'REPLACE_WITH_MACOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_MACOS_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
    iosBundleId: 'REPLACE_WITH_MACOS_BUNDLE_ID',
  );
}
