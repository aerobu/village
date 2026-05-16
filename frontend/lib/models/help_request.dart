/// A request for help (task, errand, etc.).
/// Owned by the elder; matched with volunteers by the matching engine.
class HelpRequest {
  final String id;
  final String elderId; // User ID of the person requesting help
  
  /// Type of help: 'grocery', 'transportation', 'tech-help', 'companionship', etc.
  final String type;
  
  /// Language the elder prefers: 'spanish', 'english', 'tagalog', etc.
  /// **CRITICAL:** TDD #1 rule — language outranks distance in matching.
  final String language;
  
  /// Latitude where help is needed, truncated to 2 dp for privacy.
  final double latitude;
  
  /// Longitude where help is needed, truncated to 2 dp for privacy.
  final double longitude;
  
  /// 1–5, where 5 = "needed ASAP"
  final int urgency;
  
  /// Description of the task: "Need groceries from Safeway" etc.
  final String description;
  
  /// Unix timestamp (ms) when request was created.
  final int createdMs;
  
  /// Unix timestamp (ms) when request expires (if not matched).
  /// Optional; null = no expiry.
  final int? expiresMs;
  
  /// True once a match is accepted and volunteer starts the task.
  final bool isAccepted;
  
  /// True once marked as completed.
  final bool isCompleted;

  HelpRequest({
    required this.id,
    required this.elderId,
    required this.type,
    required this.language,
    required this.latitude,
    required this.longitude,
    required this.urgency,
    required this.description,
    required this.createdMs,
    this.expiresMs,
    this.isAccepted = false,
    this.isCompleted = false,
  });

  /// Serialize to Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'elderId': elderId,
        'type': type,
        'language': language,
        'latitude': latitude,
        'longitude': longitude,
        'urgency': urgency,
        'description': description,
        'createdMs': createdMs,
        'expiresMs': expiresMs,
        'isAccepted': isAccepted,
        'isCompleted': isCompleted,
      };

  /// Deserialize from Firestore.
  factory HelpRequest.fromJson(Map<String, dynamic> json) => HelpRequest(
        id: json['id'] as String,
        elderId: json['elderId'] as String,
        type: json['type'] as String,
        language: json['language'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        urgency: json['urgency'] as int,
        description: json['description'] as String,
        createdMs: json['createdMs'] as int,
        expiresMs: json['expiresMs'] as int?,
        isAccepted: json['isAccepted'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
