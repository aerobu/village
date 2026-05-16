/// A confirmed match stored in `matches/{matchId}`.
/// Only the two participants can read this doc (enforced by Firestore rules).
///
/// Owner: B
class MatchDoc {
  const MatchDoc({
    required this.matchId,
    required this.requestId,
    required this.elderUid,
    required this.volunteerUid,
    this.acceptedAt,
    this.completedAt,
    this.proofPhotoUrl,
  });

  final String matchId;
  final String requestId;
  final String elderUid;
  final String volunteerUid;
  final DateTime? acceptedAt;   // hardcoded 3-second fake-accept timer
  final DateTime? completedAt;
  final String? proofPhotoUrl;  // hardcoded stock photo URL for demo

  // TODO(B): implement fromMap / toMap
  factory MatchDoc.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('MatchDoc.fromMap — implement in B\'s models pass');
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError('MatchDoc.toMap — implement in B\'s models pass');
  }
}
