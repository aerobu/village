import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request.dart';
import '../utils/location_utils.dart';

/// Firestore service — Person B owns this, minimal stub for C's tests.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit a help request — writes to `requests` collection.
  /// Truncates coordinates to 2 dp before write (privacy invariant for TDD #2).
  Future<String> submitRequest(HelpRequest request) async {
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

  // TODO(B): expand with matching, acceptance, completion flows
}
