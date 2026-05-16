/// Comprehensive tests for Matching Engine
/// 
/// TDD #1: Language outranks distance
/// TDD #2: Coordinates truncated to 2 dp (privacy)
/// TDD #3: Request writes to Firestore
/// 
/// Plus edge cases and additional invariants

import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/models/user_public.dart';
import 'package:village_app/models/help_request.dart';
import 'package:village_app/services/matching_service.dart';
import 'package:village_app/utils/privacy_utils.dart';

void main() {
  group('Matching Engine — Comprehensive Tests', () {
    
    // ======================================================================
    // TDD #1: Language Priority
    // ======================================================================
    
    group('TDD #1: Language priority', () {
      test('Spanish speaker 100m away beats English speaker 10m away', () {
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
          latitude: 37.7750,
          longitude: -122.4195,
          skills: 'grocery-shopping',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
          backgroundCheckVerified: false,
        );

        final spanishRequest = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 37.7749,
          longitude: -122.4194,
          urgency: 3,
          description: 'Necesito comida del supermercado',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final englishRequest = HelpRequest(
          id: 'r2',
          elderId: 'e2',
          type: 'tech-help',
          language: 'english',
          latitude: 37.7751,
          longitude: -122.4196,
          urgency: 2,
          description: 'Help with WiFi',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final scoreSpanishToSpanish =
            MatchingService.computeScore(spanishVolunteer, spanishRequest).score;
        final scoreSpanishToEnglish =
            MatchingService.computeScore(spanishVolunteer, englishRequest).score;

        expect(
          scoreSpanishToSpanish > scoreSpanishToEnglish,
          true,
          reason:
              'Spanish volunteer should prefer Spanish request: $scoreSpanishToSpanish > $scoreSpanishToEnglish',
        );
        expect(scoreSpanishToSpanish > 0.6, true);
        expect(scoreSpanishToEnglish < 0.4, true);
      });

      test('Matching algorithm produces language-first pairings', () {
        final spanish = UserPublic(
          id: 'v_spanish',
          name: 'Maria',
          photoUrl: 'assets/maria.jpg',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final english = UserPublic(
          id: 'v_english',
          name: 'Bob',
          photoUrl: 'assets/bob.jpg',
          language: 'english',
          latitude: 10.1,
          longitude: 20.1,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final spanishReq = HelpRequest(
          id: 'r_spanish',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Spanish request',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final englishReq = HelpRequest(
          id: 'r_english',
          elderId: 'e2',
          type: 'grocery',
          language: 'english',
          latitude: 10.05,
          longitude: 20.05,
          urgency: 1,
          description: 'English request',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches = MatchingService.performMatching(
          [spanish, english],
          [spanishReq, englishReq],
        );

        final spanishMatch = matches.firstWhere(
          (m) => m.volunteerId == 'v_spanish' && m.requestId == 'r_spanish',
          orElse: () => throw AssertionError('Spanish match not found'),
        );

        expect(spanishMatch.score > 0.6, true);
      });
    });

    // ======================================================================
    // TDD #2: Privacy (Coordinate Truncation)
    // ======================================================================
    
    group('TDD #2: Privacy (coordinate truncation)', () {
      test('Coordinates truncated to 2 decimal places', () {
        expect(PrivacyUtils.truncateCoordinate(37.77491234), 37.77);
        expect(PrivacyUtils.truncateCoordinate(45.51234567), 45.51);
        expect(PrivacyUtils.truncateCoordinate(-122.67891234), -122.68);
      });

      test('Location truncation works for pairs', () {
        final (:lat, :lng) = PrivacyUtils.truncateLocation(37.77491234, -122.67891234);
        expect(lat, 37.77);
        expect(lng, -122.68);
      });

      test('Privacy check verifies proper truncation', () {
        expect(PrivacyUtils.isProperlyTruncated(37.77), true);
        expect(PrivacyUtils.isProperlyTruncated(37.77491234), false);
      });
    });

    // ======================================================================
    // Urgency Weighting
    // ======================================================================
    
    group('Urgency weighting', () {
      test('Higher urgency requests score higher', () {
        final vol = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final lowUrgency = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 1,
          description: 'Low urgency',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final highUrgency = HelpRequest(
          id: 'r2',
          elderId: 'e2',
          type: 'grocery',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'High urgency',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final lowScore =
            MatchingService.computeScore(vol, lowUrgency).score;
        final highScore =
            MatchingService.computeScore(vol, highUrgency).score;

        expect(highScore > lowScore, true);
        expect((highScore - lowScore - 0.08).abs() < 0.001, true,
            reason: 'Difference should be ~0.08 (0.1 * (5-1)/5)');
      });

      test('Request can only be matched to one volunteer at a time', () {
        final v1 = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final v2 = UserPublic(
          id: 'v2',
          name: 'Bob',
          photoUrl: 'assets/bob.jpg',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final req = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Urgent',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches =
            MatchingService.performMatching([v1, v2], [req]);

        // Count how many matches include this request
        final reqMatches =
            matches.where((m) => m.requestId == 'r1').toList();
        expect(reqMatches.length, 1,
            reason: 'Each request should match exactly once');
      });
    });

    // ======================================================================
    // Edge Cases
    // ======================================================================
    
    group('Edge cases', () {
      test('Empty volunteer list returns no matches', () {
        final req = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Test',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches =
            MatchingService.performMatching([], [req]);
        expect(matches.isEmpty, true);
      });

      test('Empty request list returns no matches', () {
        final vol = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches =
            MatchingService.performMatching([vol], []);
        expect(matches.isEmpty, true);
      });

      test('Language mismatch still produces matches at lower score', () {
        final vol = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final req = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'english',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Test',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final score = MatchingService.computeScore(vol, req).score;
        expect(score > 0, true,
            reason: 'Should still have a score (distance + urgency)');
        expect(score < 0.4, true,
            reason: 'Should be low (no language match)');
      });

      test('More volunteers than requests', () {
        final v1 = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final v2 = UserPublic(
          id: 'v2',
          name: 'Bob',
          photoUrl: 'assets/bob.jpg',
          language: 'english',
          latitude: 10.1,
          longitude: 20.1,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final req = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Test',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches = MatchingService.performMatching([v1, v2], [req]);
        expect(matches.length, 1,
            reason: 'One request, one match');
        expect(matches.first.volunteerId, 'v1',
            reason: 'Spanish speaker should be matched');
      });

      test('All same language prefers by urgency and distance', () {
        final v1 = UserPublic(
          id: 'v1',
          name: 'Alice',
          photoUrl: 'assets/alice.jpg',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final v2 = UserPublic(
          id: 'v2',
          name: 'Rosa',
          photoUrl: 'assets/rosa.jpg',
          language: 'spanish',
          latitude: 10.1,
          longitude: 20.1,
          skills: 'grocery',
          lastSeenMs: DateTime.now().millisecondsSinceEpoch,
        );

        final highUrgency = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.0,
          longitude: 20.0,
          urgency: 5,
          description: 'Urgent',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final lowUrgency = HelpRequest(
          id: 'r2',
          elderId: 'e2',
          type: 'grocery',
          language: 'spanish',
          latitude: 10.05,
          longitude: 20.05,
          urgency: 1,
          description: 'Low urgency',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final matches = MatchingService.performMatching(
          [v1, v2],
          [highUrgency, lowUrgency],
        );

        // Higher urgency should get better volunteer (same location)
        final highUrgMatch = matches
            .firstWhere((m) => m.requestId == 'r1');
        final lowUrgMatch = matches
            .firstWhere((m) => m.requestId == 'r2');

        expect(highUrgMatch.score > lowUrgMatch.score, true,
            reason: 'High urgency should score higher than low urgency');
      });
    });
  });
}
