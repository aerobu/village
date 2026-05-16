/**
 * Client-side matching service.
 * 
 * Wraps the Cloud Function and provides local fallback matching.
 * Also handles caching and Firestore interactions.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_public.dart';
import '../models/help_request.dart';
import '../models/match_doc.dart';

class MatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Compute match score between a volunteer and a request.
  /// Formula: 0.7 * language + 0.2 * distance + 0.1 * urgency
  /// 
  /// TDD #1: Language outranks distance. This is the critical invariant.
  static double computeScore(UserPublic volunteer, HelpRequest request) {
    // Language match: 1.0 if same, 0.0 otherwise
    final languageMatch = volunteer.language == request.language ? 1.0 : 0.0;

    // Distance score: 1.0 if <500m, linear decay to 0.0 at 5km
    final distMeters = volunteer.distanceTo(request.latitude, request.longitude);
    const maxDist = 5000.0;
    final distScore = Math.max(0.0, 1.0 - (distMeters / maxDist));

    // Urgency score: 0.0–1.0 based on request urgency (1–5)
    final urgencyScore = request.urgency / 5.0;

    // Combined score: language is 70% of weight (highest priority)
    return 0.7 * languageMatch + 0.2 * distScore + 0.1 * urgencyScore;
  }

  /// Perform local matching (fallback if Cloud Function is unavailable).
  /// Implements a simplified Gale-Shapley algorithm.
  static List<MatchDoc> performMatching(
    List<UserPublic> volunteers,
    List<HelpRequest> requests,
  ) {
    final matches = <MatchDoc>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Simple greedy matching: for each request, find the best volunteer
    final usedVolunteers = <String>{};

    // Sort requests by urgency (most urgent first)
    final sortedRequests = [...requests]..sort((a, b) => b.urgency - a.urgency);

    for (final request in sortedRequests) {
      // Find the highest-scoring available volunteer
      double bestScore = -1.0;
      UserPublic? bestVolunteer;
      String? reason;

      for (final volunteer in volunteers) {
        if (usedVolunteers.contains(volunteer.id)) continue;

        final score = computeScore(volunteer, request);
        if (score > bestScore) {
          bestScore = score;
          bestVolunteer = volunteer;
          reason = _scoreReason(volunteer, request, score);
        }
      }

      if (bestVolunteer != null && bestScore >= 0.0) {
        usedVolunteers.add(bestVolunteer.id);
        matches.add(MatchDoc(
          id: '${bestVolunteer.id}-${request.id}',
          volunteerId: bestVolunteer.id,
          requestId: request.id,
          score: bestScore,
          reason: reason ?? 'Best available match',
          createdMs: now,
        ));
      }
    }

    return matches;
  }

  /// Human-readable explanation of a match score.
  static String _scoreReason(
    UserPublic volunteer,
    HelpRequest request,
    double score,
  ) {
    final distMeters = volunteer.distanceTo(request.latitude, request.longitude);
    final languageMatch = volunteer.language == request.language;

    if (languageMatch) {
      return '${volunteer.language} speaker, ${distMeters.toStringAsFixed(0)}m away, score ${score.toStringAsFixed(2)}';
    } else {
      return 'language mismatch, ${distMeters.toStringAsFixed(0)}m away, score ${score.toStringAsFixed(2)}';
    }
  }

  /// Fetch all matches from Firestore for a given request.
  static Future<List<MatchDoc>> getMatchesForRequest(String requestId) async {
    final snapshot = await _firestore
        .collection('matches')
        .where('requestId', isEqualTo: requestId)
        .orderBy('score', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all matches for a volunteer.
  static Future<List<MatchDoc>> getMatchesForVolunteer(
      String volunteerId) async {
    final snapshot = await _firestore
        .collection('matches')
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('score', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MatchDoc.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Accept a match (volunteer agrees to help).
  static Future<void> acceptMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'isAccepted': true,
    });
  }
}

class Math {
  static double max(double a, double b) => a > b ? a : b;
  static double min(double a, double b) => a < b ? a : b;
}
