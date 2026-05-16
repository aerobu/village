import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:village_app/utils/location_utils.dart';

void main() {
  group('TDD #2 — Privacy: pre-match coordinates truncated to 2 dp', () {
    test('truncates latitude and longitude to 2 decimal places', () {
      const precise = GeoPoint(37.7749295, -122.4194155);
      final masked = truncateTo2Dp(precise);
      expect(masked.latitude, 37.77);
      expect(masked.longitude, -122.41);
    });

    test('truncates (does not round) — floors toward zero', () {
      const precise = GeoPoint(37.779, -122.419);
      final masked = truncateTo2Dp(precise);
      expect(masked.latitude, 37.77);
      expect(masked.longitude, -122.41);
    });

    test('handles negative coordinates correctly', () {
      const precise = GeoPoint(-33.8688197, 151.2092955);
      final masked = truncateTo2Dp(precise);
      expect(masked.latitude, -33.86);
      expect(masked.longitude, 151.20);
    });

    test('already-truncated coords pass through unchanged', () {
      const alreadyMasked = GeoPoint(37.77, -122.41);
      final masked = truncateTo2Dp(alreadyMasked);
      expect(masked.latitude, 37.77);
      expect(masked.longitude, -122.41);
    });
  });
}
