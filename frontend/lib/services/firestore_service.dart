import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request.dart';
import '../utils/location_utils.dart';

/// Firestore service — Person B owns this, minimal stub for C's tests.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit a help request — writes to `requests` collection (triggers Cloud Function).
  /// Truncates approxLocation to 2 dp before write (privacy invariant).
  Future<String> submitRequest(HelpRequest request) async {
    final masked = truncateTo2Dp(request.approxLocation);
    final data = {
      'elderUid': request.elderUid,
      'needType': request.needType,
      'requiredLanguage': request.requiredLanguage,
      'approxLocation': masked,
      'status': request.status,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final ref = await _firestore.collection('requests').add(data);
    return ref.id;
  }

  // TODO(B): expand with matching, acceptance, completion flows
}
