import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/map_screen.dart';

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
