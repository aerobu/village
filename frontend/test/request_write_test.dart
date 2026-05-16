import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:village_app/models/help_request.dart';
import 'package:village_app/services/firestore_service.dart';

void main() {
  group('TDD #3 — Submit request writes to Firestore requests collection', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: fakeFirestore);
    });

    test('submitting a request creates document in requests collection', () async {
      final request = HelpRequest(
        requestId: '',
        elderUid: 'elder_1',
        needType: 'groceries',
        requiredLanguage: 'ta',
        approxLocation: const GeoPoint(37.77, -122.41),
        status: 'pending',
      );

      final docId = await service.submitRequest(request);

      final doc = await fakeFirestore.collection('requests').doc(docId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['elderUid'], 'elder_1');
      expect(doc.data()!['needType'], 'groceries');
      expect(doc.data()!['requiredLanguage'], 'ta');
      expect(doc.data()!['status'], 'pending');
    });

    test('submitted request has approxLocation truncated to 2 dp', () async {
      final request = HelpRequest(
        requestId: '',
        elderUid: 'elder_1',
        needType: 'groceries',
        requiredLanguage: 'ta',
        approxLocation: const GeoPoint(37.7749295, -122.4194155),
        status: 'pending',
      );

      final docId = await service.submitRequest(request);

      final doc = await fakeFirestore.collection('requests').doc(docId).get();
      final location = doc.data()!['approxLocation'] as GeoPoint;
      expect(location.latitude, 37.77);
      expect(location.longitude, -122.41);
    });
  });
}
