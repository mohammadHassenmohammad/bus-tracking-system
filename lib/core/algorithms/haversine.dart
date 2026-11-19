import 'dart:math' as math;

/// High-precision GIS geodesic calculations based on the Haversine formula
class Haversine {
  static const double earthRadiusMeters = 6371000.0;
  static const double earthRadiusKm = 6371.0;

  /// Calculates geodesic distance between two points in meters
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates geodesic distance between two points in kilometers
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    return distanceMeters(lat1, lon1, lat2, lon2) / 1000.0;
  }

  /// Calculates initial bearing from point 1 to point 2 in degrees [0, 360)
  static double bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final rLat1 = _toRadians(lat1);
    final rLat2 = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = (bearingRad * 180.0 / math.pi + 360.0) % 360.0;
    return bearingDeg;
  }

  /// Calculates cross-track distance (perpendicular distance) from a point P to a line segment AB
  static double crossTrackDistanceMeters(
    double pLat, double pLon,
    double aLat, double aLon,
    double bLat, double bLon,
  ) {
    final d13 = distanceMeters(aLat, aLon, pLat, pLon) / earthRadiusMeters;
    final theta13 = _toRadians(bearing(aLat, aLon, pLat, pLon));
    final theta12 = _toRadians(bearing(aLat, aLon, bLat, bLon));

    final dXt = math.asin(math.sin(d13) * math.sin(theta13 - theta12));
    return (dXt * earthRadiusMeters).abs();
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}

