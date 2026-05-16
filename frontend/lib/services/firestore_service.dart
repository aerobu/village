/**
 * Firestore service for Village.
 * Handles all Firestore CRUD operations for help requests and user profiles.
 * 
 * Owned by B (matching engine owner).
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_public.dart';
import '../models/help_request.dart';
import '../models/match_doc.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String requestsCollection = 'requests';
  static const String matchesCollection = 'matches';

  // ==================== USERS ====================

  /// Fetch a user profile by ID.
  static Future<UserPublic?> getUserProfile(String userId) async {
    final doc = await _firestore.collection(usersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return UserPublic.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Create or update a user profile.
  static Future<void> saveUserProfile(UserPublic user) async {
    await _firestore
        .collection(usersCollection)
        .doc(user.id)
        .set(user.toJson());
  }

  /// Fetch all available volunteers (active in last 24 hours).
  /// Limited to 50 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  static Future<List<UserPublic>> getAvailableVolunteers() async {
    final oneDayAgo =
        DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch;
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
    // TDD #3: Request must write to 'requests' collection
    final docRef = await _firestore
        .collection(requestsCollection)
        .add(request.toJson());
    return docRef.id;
  }

  /// Fetch a request by ID.
  static Future<HelpRequest?> getRequest(String requestId) async {
    final doc =
        await _firestore.collection(requestsCollection).doc(requestId).get();
    if (!doc.exists) return null;
    return HelpRequest.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Fetch all active requests (not completed, not expired).
  /// Limited to 50 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  static Future<List<HelpRequest>> getActiveRequests() async {
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
    await _firestore
        .collection(requestsCollection)
        .doc(requestId)
        .update(updates);
  }

  // ==================== MATCHES ====================

  /// Save a match document.
  static Future<String> saveMatch(MatchDoc match) async {
    final docRef =
        await _firestore.collection(matchesCollection).add(match.toJson());
    return docRef.id;
  }

  /// Batch save multiple matches (after algorithm runs).
  static Future<void> saveBatchMatches(List<MatchDoc> matches) async {
    final batch = _firestore.batch();
    for (final match in matches) {
      final ref = _firestore.collection(matchesCollection).doc(match.id);
      batch.set(ref, match.toJson());
    }
    await batch.commit();
  }

  /// Fetch a match by ID.
  static Future<MatchDoc?> getMatch(String matchId) async {
    final doc =
        await _firestore.collection(matchesCollection).doc(matchId).get();
    if (!doc.exists) return null;
    return MatchDoc.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Stream matches for a request (updates in real-time).
  /// Limited to 10 to stay within Spark free tier quota (see FIREBASE_LIMITS.md).
  /// Remember to dispose the listener immediately after use.
  static Stream<List<MatchDoc>> watchMatchesForRequest(String requestId) {
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
    await _firestore.collection(matchesCollection).doc(matchId).delete();
  }
}
