import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/demo_seed.dart';
import '../main.dart' show kDemoMode;
import '../models/help_request.dart';
import '../models/match_doc.dart';
import '../models/user_public.dart';

/// Firestore service — static methods for all database operations.
/// Person C provides core methods; Person B can expand.
///
/// **DEMO_MODE+web short-circuit (added by A):** the Firestore SDK on
/// Chrome was found to never resolve `set/add/commit` Futures even when
/// the underlying HTTP requests returned 200 — the form's
/// `await createRequest(...)` would hang indefinitely. When both
/// `kDemoMode` and `kIsWeb` are true, reads/writes route through
/// in-memory Map stores instead. Live mode and unit tests (Dart VM,
/// `kIsWeb == false`) use the original real-Firestore code path.
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Demo-mode in-memory stores ---------------------------------------
  static final Map<String, HelpRequest> _demoRequests = {};
  static final Map<String, MatchDoc> _demoMatches = {};

  static bool get _useDemoShortcut => kDemoMode && kIsWeb;

  // ==================== REQUESTS ====================

  /// Submit a help request — writes to `requests` collection.
  /// Truncates coordinates to 2 dp before write (privacy invariant for TDD #2).
  static Future<String> submitRequest(HelpRequest request) async {
    // Mask coordinates to 2dp for privacy (TDD #2 requirement)
    final maskedLat = (request.latitude * 100).truncate() / 100.0;
    final maskedLng = (request.longitude * 100).truncate() / 100.0;

    if (_useDemoShortcut) {
      final id = 'demo-req-${DateTime.now().millisecondsSinceEpoch}';
      _demoRequests[id] = HelpRequest(
        id: id,
        elderId: request.elderId,
        type: request.type,
        language: request.language,
        latitude: maskedLat,
        longitude: maskedLng,
        urgency: request.urgency,
        description: request.description,
        createdMs: request.createdMs,
        expiresMs: request.expiresMs,
        isAccepted: false,
        isCompleted: false,
      );
      return id;
    }

    final data = {
      'id': request.id,
      'elderId': request.elderId,
      'type': request.type,
      'language': request.language,
      'latitude': maskedLat,
      'longitude': maskedLng,
      'urgency': request.urgency,
      'description': request.description,
      'createdMs': request.createdMs,
      'isAccepted': false,
      'isCompleted': false,
    };

    final ref = await _firestore.collection('requests').add(data);
    return ref.id;
  }

  /// Create a new help request (alias for submitRequest for compatibility)
  static Future<String> createRequest(HelpRequest request) => submitRequest(request);

  /// Get a single request by ID
  static Future<HelpRequest?> getRequest(String requestId) async {
    if (_useDemoShortcut) return _demoRequests[requestId];
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) return null;
      return HelpRequest.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ==================== MATCHES ====================

  /// Get a single match by ID
  static Future<MatchDoc?> getMatch(String matchId) async {
    if (_useDemoShortcut) return _demoMatches[matchId];
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();
      if (!doc.exists) return null;
      return MatchDoc.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Accept a match
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
      }
      return;
    }
    await _firestore.collection('matches').doc(matchId).update({
      'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      'isAccepted': true,
    });
  }

  /// Decline a match
  static Future<void> declineMatch(String matchId) async {
    if (_useDemoShortcut) {
      _demoMatches.remove(matchId);
      return;
    }
    await _firestore.collection('matches').doc(matchId).update({
      'declinedAt': DateTime.now().millisecondsSinceEpoch,
      'isAccepted': false,
    });
  }

  /// Save batch of matches (from matching algorithm)
  static Future<void> saveBatchMatches(List<MatchDoc> matches) async {
    if (_useDemoShortcut) {
      for (final m in matches) {
        _demoMatches[m.id] = m;
      }
      return;
    }
    for (final match in matches) {
      await _firestore.collection('matches').doc(match.id).set(match.toJson());
    }
  }

  // ==================== USERS ====================

  /// Get a user profile by ID
  static Future<UserPublic?> getUserProfile(String userId) async {
    if (_useDemoShortcut) {
      // Volunteer lookup by ID
      for (final v in DemoSeed.volunteers) {
        if (v.id == userId) return v;
      }
      // The elder's elderId in a request is currentUser.uid (anon) — synthesize
      // a UserPublic from DemoSeed.elder with the right id.
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
    try {
      final doc = await _firestore.collection('users_public').doc(userId).get();
      if (!doc.exists) return null;
      return UserPublic.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
