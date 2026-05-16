import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/map_screen.dart';
import 'screens/request_form.dart';
import 'screens/match_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'data/demo_seed.dart';

/// When `DEMO_MODE=true` (default), the app runs entirely off `DemoSeed`
/// in-memory data and never reads from Firestore. This keeps us comfortably
/// inside the Spark free tier (see docs/FIREBASE_LIMITS.md).
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

  // Aggressive caching + offline persistence — every cached doc is a saved
  // read against our 50K/day Spark quota. (See docs/FIREBASE_LIMITS.md §5.)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 10 * 1024 * 1024, // 10 MB — plenty for this demo
  );

  // Anonymous sign-in so B's RequestFormScreen has a non-null
  // FirebaseAuth.instance.currentUser. Anonymous auth is unlimited on
  // the Spark plan (see docs/FIREBASE_LIMITS.md). Non-blocking — if it
  // fails (offline, etc.) the form will surface its own error rather
  // than the app failing to boot.
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('[main] anonymous sign-in failed: $e');
  }

  runApp(const VillageApp());
}

class VillageApp extends StatelessWidget {
  const VillageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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

