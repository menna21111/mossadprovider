import 'dart:math' as math;

/// Great-circle distance in kilometers between two WGS84 points.
double? distanceKmBetween({
  required double? fromLat,
  required double? fromLng,
  required double? toLat,
  required double? toLng,
}) {
  if (fromLat == null ||
      fromLng == null ||
      toLat == null ||
      toLng == null) {
    return null;
  }
  if (!_isValidCoord(fromLat, fromLng) || !_isValidCoord(toLat, toLng)) {
    return null;
  }

  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(toLat - fromLat);
  final dLng = _toRadians(toLng - fromLng);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(fromLat)) *
          math.cos(_toRadians(toLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double? parseCoord(dynamic value) {
  if (value == null) return null;
  final parsed = double.tryParse(value.toString().trim());
  if (parsed == null || parsed == 0) return null;
  return parsed;
}

bool _isValidCoord(double lat, double lng) {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
