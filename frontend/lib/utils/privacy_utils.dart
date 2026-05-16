/// Privacy utilities for protecting user location data.
/// TDD #2: Coordinates must be truncated to 2 decimal places (~1.1 km precision).

class PrivacyUtils {
  /// Truncate a single coordinate to 2 decimal places.
  /// 
  /// Reduces precision from ~1 meter to ~1.1 km, protecting privacy
  /// while preserving matching accuracy.
  /// 
  /// Example:
  /// - Input: 37.77491234
  /// - Output: 37.77
  static double truncateCoordinate(double value) {
    return (value * 100).round() / 100;
  }

  /// Truncate latitude and longitude to 2 decimal places.
  /// 
  /// Returns a record with truncated coordinates.
  /// Use this before saving to Firestore or passing to matching.
  static ({double lat, double lng}) truncateLocation(
    double latitude,
    double longitude,
  ) {
    return (
      lat: truncateCoordinate(latitude),
      lng: truncateCoordinate(longitude),
    );
  }

  /// Check if a coordinate is properly truncated (2 dp).
  ///
  /// Useful for testing and validation.
  /// Uses epsilon comparison for floating point safety.
  static bool isProperlyTruncated(double value) {
    final truncated = truncateCoordinate(value);
    return (value - truncated).abs() < 1e-10;
  }
}
