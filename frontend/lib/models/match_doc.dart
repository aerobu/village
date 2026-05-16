/// Output of the Gale-Shapley matching algorithm.
/// Represents a pairing of a volunteer with a help request.
class MatchDoc {
  final String id;
  final String volunteerId;
  final String requestId;
  
  /// Match quality score (0.0–1.0).
  /// Calculated by matching_service.ts based on language, distance, urgency, etc.
  /// Higher = better match.
  final double score;
  
  /// Human-readable explanation: "Spanish speaker, 200m away"
  final String reason;
  
  /// Unix timestamp (ms) when match was created by the algorithm.
  final int createdMs;
  
  /// True if the volunteer has accepted this match.
  /// Once accepted, the app shows a fake 5-second timer ("accepting...") per OWNERSHIP.md.
  final bool isAccepted;

  MatchDoc({
    required this.id,
    required this.volunteerId,
    required this.requestId,
    required this.score,
    required this.reason,
    required this.createdMs,
    this.isAccepted = false,
  });

  /// Serialize to Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'volunteerId': volunteerId,
        'requestId': requestId,
        'score': score,
        'reason': reason,
        'createdMs': createdMs,
        'isAccepted': isAccepted,
      };

  /// Deserialize from Firestore.
  factory MatchDoc.fromJson(Map<String, dynamic> json) => MatchDoc(
        id: json['id'] as String,
        volunteerId: json['volunteerId'] as String,
        requestId: json['requestId'] as String,
        score: (json['score'] as num).toDouble(),
        reason: json['reason'] as String,
        createdMs: json['createdMs'] as int,
        isAccepted: json['isAccepted'] as bool? ?? false,
      );
}
