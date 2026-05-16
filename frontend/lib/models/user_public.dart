import 'package:cloud_firestore/cloud_firestore.dart';

/// Public-facing user profile stored in `users_public/{uid}`.
/// Coordinates are truncated to 2 decimal places (~1 km) — privacy invariant.
///
/// Owner: B (flesh out fromMap/toMap); A writes the stub so demo_seed.dart compiles.
class UserPublic {
  const UserPublic({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.languages,
    required this.approxLocation,
    required this.rating,
    required this.backgroundCheck,
    this.skills = const [],
    this.needs = const [],
    this.photoUrl,
  });

  final String uid;
  final String role;            // "elder" | "volunteer"
  final String displayName;     // "Priya S."
  final List<String> languages; // ["ta", "en"]
  final GeoPoint approxLocation; // truncated to 2 dp
  final double rating;           // 0.0 – 5.0
  final bool backgroundCheck;
  final List<String> skills;    // volunteer-only
  final List<String> needs;     // elder-only
  final String? photoUrl;

  // TODO(B): implement fromMap / toMap
  factory UserPublic.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('UserPublic.fromMap — implement in B\'s models pass');
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError('UserPublic.toMap — implement in B\'s models pass');
  }
}
