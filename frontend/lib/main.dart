import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'data/demo_seed.dart';
import 'theme/app_theme.dart';
import 'screens/map_screen.dart';
import 'screens/request_form.dart';
import 'screens/match_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'data/demo_seed.dart';

/// When `DEMO_MODE=true` (default), the app runs entirely off `DemoSeed`
/// in-memory data and minimizes Firestore traffic to stay inside the Spark
/// free tier. See docs/FIREBASE_LIMITS.md.
///
/// Flip to false only when you specifically need to test the live backend:
///   flutter run -d chrome --dart-define=DEMO_MODE=false
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

/// Entry point.
/// Firebase is initialized against the `village-77ccb` project using the
/// keys in `firebase_options.dart` (fetched via the Firebase MCP).
///
/// Owner: A
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NOTE: `Settings.persistenceEnabled` was set here previously, but on
  // Flutter Web it queues writes locally and silently retries against
  // outdated security rules — that's what caused the white-screen-on-boot
  // bug after the rule changes. Web persistence is opt-in via a different
  // API (`enableIndexedDbPersistence`); we don't need it for the demo and
  // it actively hurt us. Leaving Firestore on its web default.
  //
  // Defensive: nuke any stale Firestore IndexedDB cache before the SDK
  // opens it. The web SDK uses IndexedDB internally even without
  // `persistenceEnabled`, and a corrupted DB (e.g. from a partial
  // "Clear site data" in DevTools mid-write) leaves the SDK in an
  // infinite "refusing to open IndexedDB database" retry loop that
  // blocks the entire app. clearPersistence() must run BEFORE any other
  // Firestore call, so it's the first thing here.
  try {
    await FirebaseFirestore.instance
        .clearPersistence()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    // Common: persistence already started, or nothing to clear. Fine.
    debugPrint('[main] clearPersistence skipped: $e');
  }

  // Anonymous sign-in so B's RequestFormScreen has a non-null currentUser.
  // Awaited (the form needs the uid) but capped at 5s so an unreachable
  // Firebase Auth endpoint never blocks the app from booting again.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance
          .signInAnonymously()
          .timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint('[main] anonymous sign-in failed/timed-out: $e');
  }

  // Seed the anon user's profile in /users/{uid} so MatchDetailScreen can
  // resolve the elder card. Fire-and-forget — must NOT block app boot.
  // Worst case: the match detail screen shows "Elder profile not found"
  // momentarily, which is recoverable. A hung boot is not.
  unawaited(_seedAnonElderProfileInBackground());

  runApp(const VillageApp());
}

/// Background task — pushes a /users/{uid} doc so the match detail screen
/// can render an elder card after a request is matched. Borrows fields
/// from DemoSeed.elder, stamped with the real anon UID so the security
/// rule (auth.uid == uid) is satisfied.
Future<void> _seedAnonElderProfileInBackground() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'id': uid,
          'name': DemoSeed.elder.name,
          'photoUrl': DemoSeed.elder.photoUrl,
          'language': DemoSeed.elder.language,
          'latitude': DemoSeed.elder.latitude,
          'longitude': DemoSeed.elder.longitude,
          'skills': DemoSeed.elder.skills,
          'lastSeenMs': DateTime.now().millisecondsSinceEpoch,
          'backgroundCheckVerified': false,
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('[main] /users seed failed (non-fatal): $e');
  }
}

class VillageApp extends StatelessWidget {
  const VillageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const MapScreen(),
        // Owned by B — request form
        '/request': (_) => const RequestFormScreen(),
        // Owned by C — profile screen showing elder's profile
        '/profile': (_) => ProfileScreen(user: DemoSeed.elder),
      },
      onGenerateRoute: (settings) {
        // Handle /match/:matchId route
        if (settings.name?.startsWith('/match/') == true) {
          final matchId = settings.name!.replaceFirst('/match/', '');
          return MaterialPageRoute(
            builder: (_) => MatchDetailScreen(matchId: matchId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

