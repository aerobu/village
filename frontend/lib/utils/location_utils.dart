import 'package:cloud_firestore/cloud_firestore.dart';

/// Truncates coordinates to 2 decimal places (~1 km radius).
/// Privacy invariant: pre-match coordinates exposed to frontend are masked.
GeoPoint truncateTo2Dp(GeoPoint point) {
  final lat = (point.latitude * 100).truncate() / 100.0;
  final lng = (point.longitude * 100).truncate() / 100.0;
  return GeoPoint(lat, lng);
}
