import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request.dart';
import '../models/match_doc.dart';
import '../models/user_public.dart';

/// Firestore service — static methods for all database operations.
/// Person C provides core methods; Person B can expand.
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== REQUESTS ====================

  /// Submit a help request — writes to `requests` collection.
  /// Truncates coordinates to 2 dp before write (privacy invariant for TDD #2).
  static Future<String> submitRequest(HelpRequest request) async {
    // Mask coordinates to 2dp for privacy (TDD #2 requirement)
    final maskedLat = (request.latitude * 100).truncate() / 100.0;
    final maskedLng = (request.longitude * 100).truncate() / 100.0;

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
    await _firestore.collection('matches').doc(matchId).update({
      'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      'isAccepted': true,
    });
  }

  /// Decline a match
  static Future<void> declineMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'declinedAt': DateTime.now().millisecondsSinceEpoch,
      'isAccepted': false,
    });
  }

  /// Save batch of matches (from matching algorithm)
  static Future<void> saveBatchMatches(List<MatchDoc> matches) async {
    for (final match in matches) {
      await _firestore.collection('matches').doc(match.id).set(match.toJson());
    }
  }

  // ==================== USERS ====================

  /// Get a user profile by ID
  static Future<UserPublic?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users_public').doc(userId).get();
      if (!doc.exists) return null;
      return UserPublic.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
