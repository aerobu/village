/// Test seed data for manual testing without Firestore.
/// Use these in request_form.dart or matching tests to verify logic.

import '../models/user_public.dart';
import '../models/help_request.dart';

class TestSeed {
  /// Hardcoded volunteers in Portland, OR (matches A's demo_seed.dart)
  static List<UserPublic> volunteers() => [
    UserPublic(
      id: 'vol_maria',
      name: 'Maria García',
      photoUrl: 'assets/maria.jpg',
      language: 'spanish',
      latitude: 45.5152,
      longitude: -122.6784,
      skills: 'grocery-shopping,transportation',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'vol_bob',
      name: 'Bob Smith',
      photoUrl: 'assets/bob.jpg',
      language: 'english',
      latitude: 45.5200,
      longitude: -122.6750,
      skills: 'tech-help,grocery-shopping',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    UserPublic(
      id: 'vol_rosa',
      name: 'Rosa Mendez',
      photoUrl: 'assets/rosa.jpg',
      language: 'spanish',
      latitude: 45.5165,
      longitude: -122.6800,
      skills: 'companionship,transportation',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: false,
    ),
    UserPublic(
      id: 'vol_james',
      name: 'James',
      photoUrl: 'assets/james.jpg',
      language: 'english',
      latitude: 45.5180,
      longitude: -122.6760,
      skills: 'yard-work,tech-help',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
  ];

  /// Hardcoded requests to test matching
  static List<HelpRequest> requests() => [
    HelpRequest(
      id: 'req_spanish_grocery',
      elderId: 'elder_carmen',
      type: 'grocery',
      language: 'spanish',
      latitude: 45.5150,
      longitude: -122.6780,
      urgency: 5,
      description: 'Necesito comida del supermercado',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    ),
    HelpRequest(
      id: 'req_english_tech',
      elderId: 'elder_john',
      type: 'tech-help',
      language: 'english',
      latitude: 45.5200,
      longitude: -122.6750,
      urgency: 3,
      description: 'Help me set up WiFi on my laptop',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    ),
    HelpRequest(
      id: 'req_spanish_transport',
      elderId: 'elder_juan',
      type: 'transportation',
      language: 'spanish',
      latitude: 45.5170,
      longitude: -122.6770,
      urgency: 2,
      description: 'Viaje al doctor',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  /// Expected matches (for manual verification):
  /// - req_spanish_grocery → vol_maria (Spanish speaker, same location)
  /// - req_english_tech → vol_bob (English speaker, tech skills)
  /// - req_spanish_transport → vol_rosa (Spanish speaker, transportation skill)
  ///
  /// Language always wins: if we add an English request at Maria's location,
  /// Maria should still prefer the Spanish request (TDD #1).
}
