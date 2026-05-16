/**
 * TDD #1: Language outranks distance
 * 
 * CRITICAL TEST: Verify that the matching algorithm prioritizes language
 * over proximity. A Spanish speaker 100m away should be matched with a
 * Spanish request over an English speaker 10m away.
 * 
 * This test MUST pass before B ships any matching code to main.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/models/user_public.dart';
import 'package:village_app/models/help_request.dart';
import 'package:village_app/services/matching_service.dart';

void main() {
  group('Matching Engine TDD #1: Language priority', () {
    test('Spanish speaker 100m away beats English speaker 10m away', () {
      // Setup: two volunteers
      final spanishVolunteer = UserPublic(
        id: 'v1',
        name: 'Carlos',
        photoUrl: 'assets/carlos.jpg',
        language: 'spanish',
        latitude: 37.7749,
        longitude: -122.4194,
        skills: 'grocery-shopping,tech-help',
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        backgroundCheckVerified: true,
      );

      final englishVolunteer = UserPublic(
        id: 'v2',
        name: 'Alice',
        photoUrl: 'assets/alice.jpg',
        language: 'english',
        latitude: 37.7750, // ~100m away
        longitude: -122.4195,
        skills: 'grocery-shopping',
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        backgroundCheckVerified: false,
      );

      // Two requests: Spanish (far) and English (close)
      final spanishRequest = HelpRequest(
        id: 'r1',
        elderId: 'e1',
        type: 'grocery',
        language: 'spanish',
        latitude: 37.7749,
        longitude: -122.4194,
        urgency: 3,
        description: 'Necesito comprar comida del supermercado',
        createdMs: DateTime.now().millisecondsSinceEpoch,
      );

      final englishRequest = HelpRequest(
        id: 'r2',
        elderId: 'e2',
        type: 'tech-help',
        language: 'english',
        latitude: 37.7751, // Very close to English volunteer
        longitude: -122.4196,
        urgency: 2,
        description: 'Help me set up my WiFi',
        createdMs: DateTime.now().millisecondsSinceEpoch,
      );

      // Compute scores using matching service
      final scoreSpanishVolToSpanishReq =
          MatchingService.computeScore(spanishVolunteer, spanishRequest);
      final scoreSpanishVolToEnglishReq =
          MatchingService.computeScore(spanishVolunteer, englishRequest);

      // CRITICAL ASSERTION: Language priority
      expect(
        scoreSpanishVolToSpanishReq,
        greaterThan(scoreSpanishVolToEnglishReq),
        reason: 'Spanish volunteer should prefer Spanish request '
            '(language > distance)',
      );
    });

    test('Matching produces language-first pairings', () {
      // Two volunteers, two requests
      final volunteers = [
        UserPublic(
          id: 'v_spanish',
          name: 'Maria',
          photoUrl: '',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        ),
        UserPublic(
          id: 'v_english',
          name: 'Bob',
          photoUrl: '',
          language: 'english',
          latitude: 10.1,
          longitude: 20.1,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      final requests = [
        HelpRequest(
          id: 'r_spanish',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Spanish request',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        ),
        HelpRequest(
          id: 'r_english',
          elderId: 'e2',
          type: 'grocery',
          language: 'english',
          latitude: 10.05,
          longitude: 20.05,
          urgency: 1,
          description: 'English request',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      final matches = MatchingService.performMatching(volunteers, requests);

      // Expected: Maria (Spanish) → Spanish request, Bob (English) → English request
      final spanishMatch = matches.firstWhere(
        (m) => m.volunteerId == 'v_spanish' && m.requestId == 'r_spanish',
        orElse: () => throw AssertionError('Expected Spanish match'),
      );
      expect(spanishMatch.score, greaterThan(0.6));
    });
  });
}
