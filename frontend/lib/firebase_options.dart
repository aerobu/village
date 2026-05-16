// File generated from Firebase MCP `firebase_get_sdk_config`.
//
// This file is committed by design — the keys it contains are public.
// Security comes from Firestore rules (see firestore.rules), not from
// hiding the config. (See SETUP.md §3.)
//
// To regenerate: run `flutterfire configure` against the village-77ccb
// project, OR ask Claude to re-fetch via the Firebase MCP.
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        // Android/iOS apps not registered yet — register them via
        // `flutterfire configure` once you start targeting mobile builds.
        throw UnsupportedError(
          'DefaultFirebaseOptions: Android/iOS not yet configured. '
          'Run `flutterfire configure` to register those platforms.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtT-dO37Az9ZCvptuNqGxQCFframEr86Q',
    appId: '1:415540245015:web:96acd0f38f1cee224de252',
    messagingSenderId: '415540245015',
    projectId: 'village-77ccb',
    authDomain: 'village-77ccb.firebaseapp.com',
    storageBucket: 'village-77ccb.firebasestorage.app',
  );
}
