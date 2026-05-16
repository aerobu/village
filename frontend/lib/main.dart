import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/map_screen.dart';

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
        // Owned by B — stub so routes compile
        '/request': (_) => const _PlaceholderScreen(label: 'Request Form'),
        // Owned by C — stub so routes compile
        '/profile': (_) => const _PlaceholderScreen(label: 'Profile'),
      },
    );
  }
}

/// Temporary placeholder so named routes compile before B/C add their screens.
/// DELETE once the real screens land.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
