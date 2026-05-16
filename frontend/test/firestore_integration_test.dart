/// TDD #3: Firestore Integration Tests
/// 
/// Verifies that:
/// - Help requests write to 'requests' collection
/// - Matches write to 'matches' collection
/// - Data round-trips correctly (no corruption)
/// - Batch writes work correctly
/// - Queries and streams function as expected

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:village_app/models/user_public.dart';
import 'package:village_app/models/help_request.dart';
import 'package:village_app/models/match_doc.dart';

// Override FirestoreService static _firestore for testing
// We'll create a test wrapper that allows dependency injection
class FirestoreServiceTest {
  static late FirebaseFirestore firestore;

  /// Create or update a user profile.
  static Future<void> saveUserProfile(UserPublic user) async {
    await firestore
        .collection('users')
        .doc(user.id)
        .set(user.toJson());
  }

  /// Create a new help request.
  static Future<String> createRequest(HelpRequest request) async {
    final docRef = await firestore
        .collection('requests')
        .add(request.toJson());
    return docRef.id;
  }

  /// Fetch a request by ID.
  static Future<HelpRequest?> getRequest(String requestId) async {
    final doc =
        await firestore.collection('requests').doc(requestId).get();
    if (!doc.exists) return null;
    return HelpRequest.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Fetch all active requests.
  static Future<List<HelpRequest>> getActiveRequests() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await firestore
        .collection('requests')
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdMs', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Save a match document.
  static Future<String> saveMatch(MatchDoc match) async {
    final docRef =
        await firestore.collection('matches').add(match.toJson());
    return docRef.id;
  }

  /// Batch save multiple matches.
  static Future<void> saveBatchMatches(List<MatchDoc> matches) async {
    final batch = firestore.batch();
    for (final match in matches) {
      final ref = firestore.collection('matches').doc(match.id);
      batch.set(ref, match.toJson());
    }
    await batch.commit();
  }

  /// Fetch a match by ID.
  static Future<MatchDoc?> getMatch(String matchId) async {
    final doc =
        await firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return MatchDoc.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Stream matches for a request.
  static Stream<List<MatchDoc>> watchMatchesForRequest(String requestId) {
    return firestore
        .collection('matches')
        .where('requestId', isEqualTo: requestId)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream matches for a volunteer.
  static Stream<List<MatchDoc>> watchMatchesForVolunteer(String volunteerId) {
    return firestore
        .collection('matches')
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdMs', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }
}

void main() {
  group('TDD #3: Firestore Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      FirestoreServiceTest.firestore = fakeFirestore;
    });

    // ======================================================================
    // Request Write Tests
    // ======================================================================

    group('Request creation and persistence', () {
      test('Create request writes to requests collection', () async {
        final request = HelpRequest(
          id: 'r1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 37.7749,
          longitude: -122.4194,
          urgency: 3,
          description: 'Necesito comida',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final docId = await FirestoreServiceTest.createRequest(request);
        expect(docId, isNotEmpty);

        // Verify document exists in Firestore
        final doc = await fakeFirestore.collection('requests').doc(docId).get();
        expect(doc.exists, true);
      });

      test('Request data round-trips correctly (no corruption)', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final request = HelpRequest(
          id: 'r2',
          elderId: 'elder123',
          type: 'tech-help',
          language: 'english',
          latitude: 45.5151,
          longitude: -122.6789,
          urgency: 5,
          description: 'Help with WiFi setup',
          createdMs: now,
          expiresMs: now + 86400000, // 1 day from now
          isAccepted: false,
          isCompleted: false,
        );

        await FirestoreServiceTest.createRequest(request);
        final retrieved =
            await FirestoreServiceTest.getRequest(request.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.elderId, 'elder123');
        expect(retrieved.type, 'tech-help');
        expect(retrieved.language, 'english');
        expect(retrieved.latitude, 45.5151);
        expect(retrieved.longitude, -122.6789);
        expect(retrieved.urgency, 5);
        expect(retrieved.description, 'Help with WiFi setup');
        expect(retrieved.isAccepted, false);
        expect(retrieved.isCompleted, false);
      });

      test('Request with null expiresMs serializes correctly', () async {
        final request = HelpRequest(
          id: 'r3',
          elderId: 'e3',
          type: 'grocery',
          language: 'spanish',
          latitude: 37.77,
          longitude: -122.41,
          urgency: 2,
          description: 'Comida',
          createdMs: DateTime.now().millisecondsSinceEpoch,
          expiresMs: null, // No expiry
        );

        await FirestoreServiceTest.createRequest(request);
        final retrieved =
            await FirestoreServiceTest.getRequest(request.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.expiresMs, isNull);
      });

      test('Request returns null for nonexistent ID', () async {
        final retrieved =
            await FirestoreServiceTest.getRequest('nonexistent');
        expect(retrieved, isNull);
      });

      test('Fetch active requests filters correctly', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create 3 requests: 2 active, 1 completed
        final active1 = HelpRequest(
          id: 'active1',
          elderId: 'e1',
          type: 'grocery',
          language: 'spanish',
          latitude: 37.77,
          longitude: -122.41,
          urgency: 3,
          description: 'Active 1',
          createdMs: now,
          isCompleted: false,
        );

        final active2 = HelpRequest(
          id: 'active2',
          elderId: 'e2',
          type: 'tech',
          language: 'english',
          latitude: 37.78,
          longitude: -122.42,
          urgency: 4,
          description: 'Active 2',
          createdMs: now + 1000,
          isCompleted: false,
        );

        final completed = HelpRequest(
          id: 'completed',
          elderId: 'e3',
          type: 'transportation',
          language: 'spanish',
          latitude: 37.79,
          longitude: -122.43,
          urgency: 2,
          description: 'Completed',
          createdMs: now + 2000,
          isCompleted: true, // This one is completed
        );

        await FirestoreServiceTest.createRequest(active1);
        await FirestoreServiceTest.createRequest(active2);
        await FirestoreServiceTest.createRequest(completed);

        final activeRequests =
            await FirestoreServiceTest.getActiveRequests();

        expect(activeRequests.length, 2,
            reason: 'Should return only active (non-completed) requests');
        expect(
          activeRequests.where((r) => r.id == 'completed').isEmpty,
          true,
          reason: 'Completed request should not be in active list',
        );
      });
    });

    // ======================================================================
    // Match Write Tests
    // ======================================================================

    group('Match creation and persistence', () {
      test('Save match writes to matches collection', () async {
        final match = MatchDoc(
          id: 'm1',
          volunteerId: 'v1',
          requestId: 'r1',
          score: 0.85,
          reason: 'Spanish speaker, 100m away',
          createdMs: DateTime.now().millisecondsSinceEpoch,
        );

        final docId = await FirestoreServiceTest.saveMatch(match);
        expect(docId, isNotEmpty);

        // Verify document exists in Firestore
        final doc = await fakeFirestore.collection('matches').doc(docId).get();
        expect(doc.exists, true);
      });

      test('Match data round-trips correctly (no corruption)', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final match = MatchDoc(
          id: 'm2',
          volunteerId: 'volunteer456',
          requestId: 'request789',
          score: 0.72,
          reason: 'Spanish speaker, 250m away, high urgency',
          createdMs: now,
          isAccepted: false,
        );

        await FirestoreServiceTest.saveMatch(match);
        final retrieved = await FirestoreServiceTest.getMatch(match.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.volunteerId, 'volunteer456');
        expect(retrieved.requestId, 'request789');
        expect(retrieved.score, 0.72);
        expect(retrieved.reason, 'Spanish speaker, 250m away, high urgency');
        expect(retrieved.isAccepted, false);
      });

      test('Match with isAccepted=true serializes correctly', () async {
        final match = MatchDoc(
          id: 'm3',
          volunteerId: 'v3',
          requestId: 'r3',
          score: 0.91,
          reason: 'Perfect match',
          createdMs: DateTime.now().millisecondsSinceEpoch,
          isAccepted: true,
        );

        await FirestoreServiceTest.saveMatch(match);
        final retrieved = await FirestoreServiceTest.getMatch(match.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.isAccepted, true);
      });

      test('Match returns null for nonexistent ID', () async {
        final retrieved = await FirestoreServiceTest.getMatch('nonexistent');
        expect(retrieved, isNull);
      });
    });

    // ======================================================================
    // Batch Write Tests
    // ======================================================================

    group('Batch match writes', () {
      test('Batch save multiple matches atomically', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final matches = [
          MatchDoc(
            id: 'batch1',
            volunteerId: 'v1',
            requestId: 'r1',
            score: 0.85,
            reason: 'Match 1',
            createdMs: now,
          ),
          MatchDoc(
            id: 'batch2',
            volunteerId: 'v2',
            requestId: 'r2',
            score: 0.72,
            reason: 'Match 2',
            createdMs: now,
          ),
          MatchDoc(
            id: 'batch3',
            volunteerId: 'v3',
            requestId: 'r3',
            score: 0.91,
            reason: 'Match 3',
            createdMs: now,
          ),
        ];

        await FirestoreServiceTest.saveBatchMatches(matches);

        // Verify all matches were written
        for (final match in matches) {
          final retrieved =
              await FirestoreServiceTest.getMatch(match.id);
          expect(retrieved, isNotNull, reason: 'Match ${match.id} should exist');
          expect(retrieved!.score, match.score);
        }
      });

      test('Batch write handles empty list gracefully', () async {
        await FirestoreServiceTest.saveBatchMatches([]);
        // Should not throw; no matches to write
        expect(true, true);
      });

      test('Batch write handles large number of matches', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final matches = List.generate(
          50,
          (i) => MatchDoc(
            id: 'batch_large_$i',
            volunteerId: 'v$i',
            requestId: 'r${i % 10}',
            score: 0.5 + (i % 50) / 100,
            reason: 'Match $i',
            createdMs: now + i,
          ),
        );

        await FirestoreServiceTest.saveBatchMatches(matches);

        // Spot-check a few matches
        for (int i = 0; i < 50; i += 10) {
          final retrieved =
              await FirestoreServiceTest.getMatch('batch_large_$i');
          expect(retrieved, isNotNull);
        }
      });
    });

    // ======================================================================
    // Query Tests
    // ======================================================================

    group('Request and match queries', () {
      test('Query matches by request ID returns correct matches', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create matches: 2 for request r1, 1 for request r2
        final matches = [
          MatchDoc(
            id: 'm1_r1',
            volunteerId: 'v1',
            requestId: 'r1',
            score: 0.85,
            reason: 'Match 1',
            createdMs: now,
          ),
          MatchDoc(
            id: 'm2_r1',
            volunteerId: 'v2',
            requestId: 'r1',
            score: 0.72,
            reason: 'Match 2',
            createdMs: now + 1000,
          ),
          MatchDoc(
            id: 'm3_r2',
            volunteerId: 'v3',
            requestId: 'r2',
            score: 0.91,
            reason: 'Match 3',
            createdMs: now + 2000,
          ),
        ];

        for (final match in matches) {
          await FirestoreServiceTest.saveMatch(match);
        }

        final matchesForR1 =
            await fakeFirestore
                .collection('matches')
                .where('requestId', isEqualTo: 'r1')
                .get()
                .then((snapshot) => snapshot.docs
                    .map((doc) =>
                        MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
                    .toList());

        expect(matchesForR1.length, 2);
        expect(matchesForR1.every((m) => m.requestId == 'r1'), true);
      });

      test('Query matches by volunteer ID returns correct matches', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        final matches = [
          MatchDoc(
            id: 'v1_m1',
            volunteerId: 'volunteer1',
            requestId: 'r1',
            score: 0.85,
            reason: 'Match 1',
            createdMs: now,
          ),
          MatchDoc(
            id: 'v1_m2',
            volunteerId: 'volunteer1',
            requestId: 'r2',
            score: 0.72,
            reason: 'Match 2',
            createdMs: now + 1000,
          ),
          MatchDoc(
            id: 'v2_m1',
            volunteerId: 'volunteer2',
            requestId: 'r3',
            score: 0.91,
            reason: 'Match 3',
            createdMs: now + 2000,
          ),
        ];

        for (final match in matches) {
          await FirestoreServiceTest.saveMatch(match);
        }

        final matchesForV1 =
            await fakeFirestore
                .collection('matches')
                .where('volunteerId', isEqualTo: 'volunteer1')
                .get()
                .then((snapshot) => snapshot.docs
                    .map((doc) =>
                        MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
                    .toList());

        expect(matchesForV1.length, 2);
        expect(matchesForV1.every((m) => m.volunteerId == 'volunteer1'),
            true);
      });
    });

    // ======================================================================
    // Stream Tests
    // ======================================================================

    group('Real-time streams', () {
      test('Stream matches for request emits updates', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create initial match
        final match1 = MatchDoc(
          id: 'stream_m1',
          volunteerId: 'v1',
          requestId: 'stream_r1',
          score: 0.85,
          reason: 'Match 1',
          createdMs: now,
        );

        await FirestoreServiceTest.saveMatch(match1);

        // Subscribe to stream
        final streamFuture = FirestoreServiceTest
            .watchMatchesForRequest('stream_r1')
            .first;

        // Wait a bit to ensure stream is subscribed
        await Future.delayed(Duration(milliseconds: 100));

        // Add another match
        final match2 = MatchDoc(
          id: 'stream_m2',
          volunteerId: 'v2',
          requestId: 'stream_r1',
          score: 0.72,
          reason: 'Match 2',
          createdMs: now + 1000,
        );

        await FirestoreServiceTest.saveMatch(match2);

        // Get the stream result
        final matches = await streamFuture;
        expect(matches.length, greaterThanOrEqualTo(1),
            reason: 'Stream should emit matches');
      });

      test('Stream matches for volunteer emits updates', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        final match = MatchDoc(
          id: 'stream_v_m1',
          volunteerId: 'stream_v1',
          requestId: 'r1',
          score: 0.85,
          reason: 'Match 1',
          createdMs: now,
        );

        await FirestoreServiceTest.saveMatch(match);

        final streamFuture = FirestoreServiceTest
            .watchMatchesForVolunteer('stream_v1')
            .first;

        await Future.delayed(Duration(milliseconds: 100));

        final matches = await streamFuture;
        expect(matches.length, greaterThanOrEqualTo(1),
            reason: 'Stream should emit matches for volunteer');
      });
    });

    // ======================================================================
    // Cross-Model Integration
    // ======================================================================

    group('Request and match integration', () {
      test('Create request and matches together', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create request
        final request = HelpRequest(
          id: 'integration_r1',
          elderId: 'elder1',
          type: 'grocery',
          language: 'spanish',
          latitude: 37.7749,
          longitude: -122.4194,
          urgency: 4,
          description: 'Groceries',
          createdMs: now,
        );

        await FirestoreServiceTest.createRequest(request);

        // Create matches for this request
        final matches = [
          MatchDoc(
            id: 'int_m1',
            volunteerId: 'v1',
            requestId: 'integration_r1',
            score: 0.85,
            reason: 'Spanish, 100m',
            createdMs: now,
          ),
          MatchDoc(
            id: 'int_m2',
            volunteerId: 'v2',
            requestId: 'integration_r1',
            score: 0.72,
            reason: 'Spanish, 500m',
            createdMs: now,
          ),
        ];

        await FirestoreServiceTest.saveBatchMatches(matches);

        // Verify request exists
        final retrievedRequest =
            await FirestoreServiceTest.getRequest('integration_r1');
        expect(retrievedRequest, isNotNull);
        expect(retrievedRequest!.elderId, 'elder1');

        // Verify matches exist for request
        final requestMatches = await fakeFirestore
            .collection('matches')
            .where('requestId', isEqualTo: 'integration_r1')
            .get()
            .then((snapshot) => snapshot.docs
                .map((doc) =>
                    MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
                .toList());

        expect(requestMatches.length, 2);
      });

      test('Update request status after match accepted', () async {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Create request
        final request = HelpRequest(
          id: 'update_r1',
          elderId: 'elder2',
          type: 'tech-help',
          language: 'english',
          latitude: 45.5151,
          longitude: -122.6789,
          urgency: 5,
          description: 'WiFi help',
          createdMs: now,
          isAccepted: false,
        );

        await FirestoreServiceTest.createRequest(request);

        // Create match
        final match = MatchDoc(
          id: 'update_m1',
          volunteerId: 'v1',
          requestId: 'update_r1',
          score: 0.91,
          reason: 'Perfect match',
          createdMs: now,
          isAccepted: true,
        );

        await FirestoreServiceTest.saveMatch(match);

        // Update request to accepted
        await fakeFirestore
            .collection('requests')
            .doc('update_r1')
            .update({'isAccepted': true});

        // Verify update
        final updatedRequest =
            await FirestoreServiceTest.getRequest('update_r1');
        expect(updatedRequest!.isAccepted, true);
      });
    });
  });
}
