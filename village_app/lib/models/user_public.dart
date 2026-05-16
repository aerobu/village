/// Public profile of a volunteer or elder.
/// Shared between the client and Firestore.
class UserPublic {
  final String id;
  final String name;
  final String photoUrl;
  
  /// Primary language: 'spanish', 'tagalog', 'english', etc.
  final String language;
  
  /// Latitude, truncated to 2 decimal places for privacy (~1.1 km precision).
  /// See OWNERSHIP.md TDD #2: coords truncated to 2 dp before matching.
  final double latitude;
  
  /// Longitude, truncated to 2 decimal places for privacy.
  final double longitude;
  
  /// Comma-separated skills: 'grocery-shopping', 'tech-help', 'transportation', etc.
  final String skills;
  
  /// Unix timestamp (milliseconds) of last activity.
  final int lastSeenMs;
  
  /// True if this user has passed background check (C owns this).
  final bool backgroundCheckVerified;

  UserPublic({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.language,
    required this.latitude,
    required this.longitude,
    required this.skills,
    required this.lastSeenMs,
    this.backgroundCheckVerified = false,
  });

  /// Distance in meters between this user and a given lat/lng.
  double distanceTo(double lat, double lng) {
    return _haversineDistance(latitude, longitude, lat, lng);
  }

  /// Haversine formula for distance in meters.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRad(lat1)) *
            Math.cos(_toRad(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * (3.14159265359 / 180);

  /// Serialize to Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoUrl': photoUrl,
        'language': language,
        'latitude': latitude,
        'longitude': longitude,
        'skills': skills,
        'lastSeenMs': lastSeenMs,
        'backgroundCheckVerified': backgroundCheckVerified,
      };

  /// Deserialize from Firestore.
  factory UserPublic.fromJson(Map<String, dynamic> json) => UserPublic(
        id: json['id'] as String,
        name: json['name'] as String,
        photoUrl: json['photoUrl'] as String,
        language: json['language'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        skills: json['skills'] as String,
        lastSeenMs: json['lastSeenMs'] as int,
        backgroundCheckVerified:
            json['backgroundCheckVerified'] as bool? ?? false,
      );
}
