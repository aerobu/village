import '../models/user_public.dart';

/// Hardcoded demo data — 5 volunteers + 1 elder.
///
/// All coordinates are truncated to 2 decimal places (~1 km) per the
/// privacy invariant in CLAUDE.md. They're clustered around downtown
/// Portland, OR for demo plausibility.
///
/// ⚠️ FREE TIER GUARDRAIL: this list must stay in-memory. Do NOT replace it
/// with a Firestore query — that would burn through the 50K reads/day Spark
/// quota on a busy demo. See docs/FIREBASE_LIMITS.md.
///
/// Run with: --dart-define=DEMO_SEED=true (and DEMO_MODE=true, the default)
///
/// ⚠️ SCHEMA DIVERGENCE: this file adapts to B's actual UserPublic shape,
/// which differs from docs/SCHEMA.md (B uses `id`/`name`/`language`/
/// `latitude`/`longitude`/`skills` (comma-separated)/`backgroundCheckVerified`
/// and dropped `role`/`rating`/`needs`). Elder vs volunteer is tracked here
/// by separation (DemoSeed.elder vs DemoSeed.volunteers), not by a field.
///
/// Owner: A
abstract class DemoSeed {
  /// Whether the app was launched with the demo-seed flag.
  static const bool enabled =
      bool.fromEnvironment('DEMO_SEED', defaultValue: false);

  /// Recent timestamp for `lastSeenMs` (B's matching may filter on this).
  /// Computed once at static init.
  static final int _now = DateTime.now().millisecondsSinceEpoch;

  /// The "elder" user — this is the logged-in demo persona.
  static final UserPublic elder = UserPublic(
    id: 'demo-elder-001',
    name: 'Meena R.',
    photoUrl: '',
    language: 'tamil',
    latitude: 45.52, // downtown Portland, Pearl District, 2dp
    longitude: -122.68,
    skills: '', // elders don't have skills, they have needs
    lastSeenMs: _now,
    backgroundCheckVerified: false,
  );

  /// Five volunteers — varied language, skill, and location spread.
  ///
  /// TDD #1 storytelling: Arjun is geographically closest but speaks Hindi.
  /// Priya speaks Tamil (the elder's language) so she should rank #1 despite
  /// being slightly further. Ravi also speaks Tamil but is further still.
  static final List<UserPublic> volunteers = [
    UserPublic(
      id: 'demo-vol-001',
      name: 'Priya S.',
      photoUrl: '',
      language: 'tamil', // language match — should rank #1
      latitude: 45.53,   // NW Portland
      longitude: -122.69,
      skills: 'groceries,companionship',
      lastSeenMs: _now,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-002',
      name: 'Arjun M.',
      photoUrl: '',
      language: 'hindi', // closer, but no Tamil
      latitude: 45.51,
      longitude: -122.67,
      skills: 'groceries,transport',
      lastSeenMs: _now,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-003',
      name: 'Sunita B.',
      photoUrl: '',
      language: 'bengali',
      latitude: 45.52, // West Portland
      longitude: -122.70,
      skills: 'companionship',
      lastSeenMs: _now,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-004',
      name: 'Ravi K.',
      photoUrl: '',
      language: 'tamil', // also Tamil — further away than Priya
      latitude: 45.54,   // North Portland
      longitude: -122.68,
      skills: 'transport,groceries',
      lastSeenMs: _now,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'demo-vol-005',
      name: 'Ananya P.',
      photoUrl: '',
      language: 'hindi',
      latitude: 45.53, // NE Portland
      longitude: -122.66,
      skills: 'companionship',
      lastSeenMs: _now,
      backgroundCheckVerified: false,
    ),
  ];

  /// All map pins: elder + volunteers.
  static List<UserPublic> get allPins => [elder, ...volunteers];

  /// True if the given user is the demo elder (used by map_screen for the
  /// elder/volunteer marker styling — B's UserPublic doesn't carry a `role`).
  static bool isElder(UserPublic user) => user.id == elder.id;
}
