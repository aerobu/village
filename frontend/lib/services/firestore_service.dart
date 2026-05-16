/// Firestore service for Village.
/// Handles all Firestore CRUD operations for help requests and user profiles.
///
/// Owned by B. Edited by A to add an in-memory short-circuit for the demo
/// path on Flutter Web — the Firestore SDK on Chrome was hanging on
/// `set/add/commit` Futures even though the network requests themselves
/// returned 200, which would otherwise leave the request form spinning
/// indefinitely on submit.
///
/// The short-circuit ONLY triggers when both:
///   - `DEMO_MODE` compile-time flag is true (the default for `flutter run -d chrome`)
///   - we're running on the web target (`kIsWeb`)
///
/// On native targets and in unit tests (which run on the Dart VM, not web),
/// the original real-Firestore code path is preserved unchanged — that's
/// what `fake_cloud_firestore`-based tests like `firestore_integration_test.dart`
/// exercise.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/demo_seed.dart';
import '../main.dart' show kDemoMode;
import '../models/user_public.dart';
import '../models/help_request.dart';
import '../models/match_doc.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String requestsCollection = 'requests';
  static const String matchesCollection = 'matches';

  // ---- Demo-mode in-memory stores ----------------------------------------
  // These survive within a single page session but reset on hot restart.
  // Only accessed when `_useDemoShortcut` is true.
  static final Map<String, HelpRequest> _demoRequests = {};
  static final Map<String, MatchDoc> _demoMatches = {};

  /// Returns true if we should use the in-memory demo store rather than
  /// the real Firestore SDK. Web-only by design — see file header.
  static bool get _useDemoShortcut => kDemoMode && kIsWeb;

  // ==================== USERS ====================

  /// Fetch a user profile by ID.
  static Future<UserPublic?> getUserProfile(String userId) async {
    if (_useDemoShortcut) {
      // Volunteer lookup by ID
      for (final v in DemoSeed.volunteers) {
        if (v.id == userId) return v;
      }
      // The elder's elderId in a request is currentUser.uid (anon). When
      // the match detail screen looks that up here, synthesize a user
      // profile from DemoSeed.elder with the right id.
      final anonUid = FirebaseAuth.instance.currentUser?.uid;
      if (userId == anonUid || userId == DemoSeed.elder.id) {
        return UserPublic(
          id: userId,
          name: DemoSeed.elder.name,
          photoUrl: DemoSeed.elder.photoUrl,
          language: DemoSeed.elder.language,
          latitude: DemoSeed.elder.latitude,
          longitude: DemoSeed.elder.longitude,
          skills: DemoSeed.elder.skills,
          lastSeenMs: DemoSeed.elder.lastSeenMs,
          backgroundCheckVerified: DemoSeed.elder.backgroundCheckVerified,
        );
      }
      return null;
    }
    final doc = await _firestore.collection(usersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return UserPublic.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Create or update a user profile.
  static Future<void> saveUserProfile(UserPublic user) async {
    if (_useDemoShortcut) return; // no-op in demo
    await _firestore
        .collection(usersCollection)
        .doc(user.id)
        .set(user.toJson());
  }

  /// Fetch all available volunteers (active in last 24 hours).
  /// Limited to 50 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  static Future<List<UserPublic>> getAvailableVolunteers() async {
    if (_useDemoShortcut) return DemoSeed.volunteers;
    final oneDayAgo =
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('lastSeenMs', isGreaterThan: oneDayAgo)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => UserPublic.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ==================== REQUESTS ====================

  /// Create a new help request.
  static Future<String> createRequest(HelpRequest request) async {
    if (_useDemoShortcut) {
      final id = 'demo-req-${DateTime.now().millisecondsSinceEpoch}';
      _demoRequests[id] = HelpRequest(
        id: id,
        elderId: request.elderId,
        type: request.type,
        language: request.language,
        latitude: request.latitude,
        longitude: request.longitude,
        urgency: request.urgency,
        description: request.description,
        createdMs: request.createdMs,
        expiresMs: request.expiresMs,
        isAccepted: request.isAccepted,
        isCompleted: request.isCompleted,
      );
      return id;
    }
    // TDD #3: Request must write to 'requests' collection
    final docRef = await _firestore
        .collection(requestsCollection)
        .add(request.toJson());
    return docRef.id;
  }

  /// Fetch a request by ID.
  static Future<HelpRequest?> getRequest(String requestId) async {
    if (_useDemoShortcut) return _demoRequests[requestId];
    final doc =
        await _firestore.collection(requestsCollection).doc(requestId).get();
    if (!doc.exists) return null;
    return HelpRequest.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Fetch all active requests (not completed, not expired).
  /// Limited to 50 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  static Future<List<HelpRequest>> getActiveRequests() async {
    if (_useDemoShortcut) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return _demoRequests.values
          .where((r) =>
              !r.isCompleted && (r.expiresMs == null || r.expiresMs! > now))
          .toList();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _firestore
        .collection(requestsCollection)
        .where('isCompleted', isEqualTo: false)
        .where('expiresMs', isGreaterThan: now)
        .orderBy('createdMs', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Fetch requests by elder ID.
  /// Limited to 20 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  static Future<List<HelpRequest>> getRequestsByElder(String elderId) async {
    if (_useDemoShortcut) {
      return _demoRequests.values.where((r) => r.elderId == elderId).toList();
    }
    final snapshot = await _firestore
        .collection(requestsCollection)
        .where('elderId', isEqualTo: elderId)
        .orderBy('createdMs', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => HelpRequest.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Update request status (accept, complete, etc.).
  static Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    if (_useDemoShortcut) {
      final existing = _demoRequests[requestId];
      if (existing == null) return;
      _demoRequests[requestId] = HelpRequest(
        id: existing.id,
        elderId: existing.elderId,
        type: existing.type,
        language: existing.language,
        latitude: existing.latitude,
        longitude: existing.longitude,
        urgency: existing.urgency,
        description: existing.description,
        createdMs: existing.createdMs,
        expiresMs: existing.expiresMs,
        isAccepted: updates['isAccepted'] as bool? ?? existing.isAccepted,
        isCompleted: updates['isCompleted'] as bool? ?? existing.isCompleted,
      );
      return;
    }
    await _firestore
        .collection(requestsCollection)
        .doc(requestId)
        .update(updates);
  }

  // ==================== MATCHES ====================

  /// Save a match document.
  static Future<String> saveMatch(MatchDoc match) async {
    if (_useDemoShortcut) {
      _demoMatches[match.id] = match;
      return match.id;
    }
    final docRef =
        await _firestore.collection(matchesCollection).add(match.toJson());
    return docRef.id;
  }

  /// Batch save multiple matches (after algorithm runs).
  static Future<void> saveBatchMatches(List<MatchDoc> matches) async {
    if (_useDemoShortcut) {
      for (final m in matches) {
        _demoMatches[m.id] = m;
      }
      return;
    }
    final batch = _firestore.batch();
    for (final match in matches) {
      final ref = _firestore.collection(matchesCollection).doc(match.id);
      batch.set(ref, match.toJson());
    }
    await batch.commit();
  }

  /// Fetch a match by ID.
  static Future<MatchDoc?> getMatch(String matchId) async {
    if (_useDemoShortcut) return _demoMatches[matchId];
    final doc =
        await _firestore.collection(matchesCollection).doc(matchId).get();
    if (!doc.exists) return null;
    return MatchDoc.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Stream matches for a request (updates in real-time).
  /// Limited to 10 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  /// Remember to dispose the listener immediately after use.
  static Stream<List<MatchDoc>> watchMatchesForRequest(String requestId) {
    if (_useDemoShortcut) {
      final list = _demoMatches.values
          .where((m) => m.requestId == requestId)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return Stream.value(list);
    }
    return _firestore
        .collection(matchesCollection)
        .where('requestId', isEqualTo: requestId)
        .orderBy('score', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream matches for a volunteer (updates in real-time).
  /// Limited to 20 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  /// Remember to dispose the listener immediately after use.
  static Stream<List<MatchDoc>> watchMatchesForVolunteer(String volunteerId) {
    if (_useDemoShortcut) {
      final list = _demoMatches.values
          .where((m) => m.volunteerId == volunteerId)
          .toList()
        ..sort((a, b) => b.createdMs.compareTo(a.createdMs));
      return Stream.value(list);
    }
    return _firestore
        .collection(matchesCollection)
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdMs', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Accept a match (volunteer has agreed to help).
  /// Updates isAccepted flag and the corresponding request.
  static Future<void> acceptMatch(String matchId) async {
    if (_useDemoShortcut) {
      final m = _demoMatches[matchId];
      if (m != null) {
        _demoMatches[matchId] = MatchDoc(
          id: m.id,
          volunteerId: m.volunteerId,
          requestId: m.requestId,
          score: m.score,
          reason: m.reason,
          createdMs: m.createdMs,
          isAccepted: true,
        );
        final r = _demoRequests[m.requestId];
        if (r != null) {
          _demoRequests[m.requestId] = HelpRequest(
            id: r.id,
            elderId: r.elderId,
            type: r.type,
            language: r.language,
            latitude: r.latitude,
            longitude: r.longitude,
            urgency: r.urgency,
            description: r.description,
            createdMs: r.createdMs,
            expiresMs: r.expiresMs,
            isAccepted: true,
            isCompleted: r.isCompleted,
          );
        }
      }
      return;
    }
    final batch = _firestore.batch();

    // Update match document
    final matchRef = _firestore.collection(matchesCollection).doc(matchId);
    batch.update(matchRef, {'isAccepted': true});

    // Also update the corresponding request to isAccepted
    final matchDoc = await matchRef.get();
    if (matchDoc.exists) {
      final match = MatchDoc.fromJson(matchDoc.data() as Map<String, dynamic>);
      final requestRef = _firestore
          .collection(requestsCollection)
          .doc(match.requestId);
      batch.update(requestRef, {'isAccepted': true});
    }

    await batch.commit();
  }

  /// Decline a match (volunteer is not interested).
  /// Currently just removes the match document.
  /// TODO: In production, might want to keep it and mark isDeclined=true
  static Future<void> declineMatch(String matchId) async {
    if (_useDemoShortcut) {
      _demoMatches.remove(matchId);
      return;
    }
    await _firestore.collection(matchesCollection).doc(matchId).delete();
  }
}
