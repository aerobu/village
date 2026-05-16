import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_public.dart';

/// Hardcoded demo data — 5 volunteers + 1 elder.
///
/// All coordinates are truncated to 2 decimal places (~1 km) per the
/// privacy invariant in CLAUDE.md. They're clustered around a small
/// downtown Portland, OR for demo plausibility.
///
/// Run with: --dart-define=DEMO_SEED=true
///
/// Owner: A
abstract class DemoSeed {
  /// Whether the app was launched with the demo-seed flag.
  static const bool enabled =
      bool.fromEnvironment('DEMO_SEED', defaultValue: false);

  /// The "elder" user — this is the logged-in demo persona.
  static const UserPublic elder = UserPublic(
    uid: 'demo-elder-001',
    role: 'elder',
    displayName: 'Meena R.',
    languages: ['ta', 'en'],
    approxLocation: GeoPoint(45.52, -122.68), // downtown Portland, Pearl District, 2dp
    rating: 4.8,
    backgroundCheck: false,
    needs: ['groceries', 'companionship'],
  );

  /// Five volunteers — varied language, skill, and location spread.
  static const List<UserPublic> volunteers = [
    UserPublic(
      uid: 'demo-vol-001',
      role: 'volunteer',
      displayName: 'Priya S.',
      languages: ['ta', 'en'],        // Tamil match — should rank #1
      approxLocation: GeoPoint(45.53, -122.69) // NW Portland,
      rating: 4.9,
      backgroundCheck: true,
      skills: ['groceries', 'companionship'],
    ),
    UserPublic(
      uid: 'demo-vol-002',
      role: 'volunteer',
      displayName: 'Arjun M.',
      languages: ['hi', 'en'],
      approxLocation: GeoPoint(45.51, -122.67), // closer, but no Tamil
      rating: 4.7,
      backgroundCheck: true,
      skills: ['groceries', 'transport'],
    ),
    UserPublic(
      uid: 'demo-vol-003',
      role: 'volunteer',
      displayName: 'Sunita B.',
      languages: ['bn', 'en'],
      approxLocation: GeoPoint(45.52, -122.70) // West Portland,
      rating: 4.6,
      backgroundCheck: true,
      skills: ['companionship'],
    ),
    UserPublic(
      uid: 'demo-vol-004',
      role: 'volunteer',
      displayName: 'Ravi K.',
      languages: ['ta', 'hi', 'en'],  // also speaks Tamil
      approxLocation: GeoPoint(45.54, -122.68) // North Portland,
      rating: 4.5,
      backgroundCheck: true,
      skills: ['transport', 'groceries'],
    ),
    UserPublic(
      uid: 'demo-vol-005',
      role: 'volunteer',
      displayName: 'Ananya P.',
      languages: ['hi', 'bn'],
      approxLocation: GeoPoint(45.53, -122.66) // NE Portland,
      rating: 4.4,
      backgroundCheck: false,
      skills: ['companionship'],
    ),
  ];

  /// All map pins: elder + volunteers.
  static List<UserPublic> get allPins => [elder, ...volunteers];
}
