import 'package:cloud_firestore/cloud_firestore.dart';

/// A help request stored in `requests/{requestId}`.
/// Writing here triggers the Cloud Function (TDD test #3).
///
/// Owner: B
class HelpRequest {
  const HelpRequest({
    required this.requestId,
    required this.elderUid,
    required this.needType,
    required this.requiredLanguage,
    required this.approxLocation,
    this.status = 'pending',
    this.matchId,
  });

  final String requestId;
  final String elderUid;
  final String needType;          // "groceries" | "companionship" | "transport"
  final String requiredLanguage;  // "ta" | "hi" | "bn" | "en"
  final GeoPoint approxLocation;  // truncated to 2 dp
  final String status;            // "pending" → "matched" → "completed"
  final String? matchId;

  // TODO(B): implement fromMap / toMap
  factory HelpRequest.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('HelpRequest.fromMap — implement in B\'s models pass');
  }

  Map<String, dynamic> toMap() {
    throw UnimplementedError('HelpRequest.toMap — implement in B\'s models pass');
  }
}
