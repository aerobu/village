import '../models/user_public.dart';

/// Hardcoded demo data — 5 volunteers + 1 elder.
///
/// All coordinates are truncated to 2 decimal places (~1 km) per the
/// privacy invariant in CLAUDE.md. They're clustered around a small
/// downtown Portland, OR for demo plausibility.
///
/// ⚠️ FREE TIER GUARDRAIL: this list must stay in-memory. Do NOT replace it
/// with a Firestore query — that would burn through the 50K reads/day Spark
/// quota on a busy demo. See docs/FIREBASE_LIMITS.md.
///
/// Owner: A
abstract class DemoSeed {
  /// The "elder" user — this is the logged-in demo persona.
  static final UserPublic elder = UserPublic(
    id: 'demo-elder-001',
    name: 'Meena R.',
    photoUrl: 'https://via.placeholder.com/100?text=MR',
    language: 'tamil',
    latitude: 45.52, // downtown Portland, Pearl District, 2dp
    longitude: -122.68,
    skills: 'grocery-shopping,companionship',
    lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    backgroundCheckVerified: false,
  );

  /// Five volunteers — varied language, skill, and location spread.
  static final List<UserPublic> volunteers = [
    UserPublic(
      id: 'demo-vol-001',
      name: 'Priya S.',
      photoUrl: 'https://via.placeholder.com/100?text=PS',
      language: 'tamil', // Tamil match — should rank #1
      latitude: 45.53, // NW Portland
      longitude: -122.69,
      skills: 'grocery-shopping,companionship',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-002',
      name: 'Arjun M.',
      photoUrl: 'https://via.placeholder.com/100?text=AM',
      language: 'hindi',
      latitude: 45.51, // closer, but no Tamil
      longitude: -122.67,
      skills: 'grocery-shopping,transportation',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-003',
      name: 'Sunita B.',
      photoUrl: 'https://via.placeholder.com/100?text=SB',
      language: 'bengali',
      latitude: 45.52, // West Portland
      longitude: -122.70,
      skills: 'companionship',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-004',
      name: 'Ravi K.',
      photoUrl: 'https://via.placeholder.com/100?text=RK',
      language: 'tamil', // also speaks Tamil
      latitude: 45.54, // North Portland
      longitude: -122.68,
      skills: 'transportation,grocery-shopping',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-005',
      name: 'Ananya P.',
      photoUrl: 'https://via.placeholder.com/100?text=AP',
      language: 'hindi',
      latitude: 45.53, // NE Portland
      longitude: -122.66,
      skills: 'companionship',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: false,
    ),
  ];

  /// All map pins: elder + volunteers.
  static List<UserPublic> get allPins => [elder, ...volunteers];

  /// Helper: check if a user is the elder (logged-in demo persona)
  static bool isElder(UserPublic user) => user.id == elder.id;

  /// Helper: check if a user is a volunteer
  static bool isVolunteer(UserPublic user) => volunteers.any((v) => v.id == user.id);
}
