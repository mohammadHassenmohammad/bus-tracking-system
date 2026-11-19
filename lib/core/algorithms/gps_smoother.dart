import 'dart:math' as math;
import 'haversine.dart';

class RawGpsSample {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final double speed; // m/s
  final double heading; // degrees
  final DateTime timestamp;

  const RawGpsSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}

class FilteredGpsPosition {
  final double latitude;
  final double longitude;
  final double smoothedSpeedKmh;
  final double heading;
  final DateTime timestamp;
  final bool isValid;
  final String rejectionReason;

  const FilteredGpsPosition({
    required this.latitude,
    required this.longitude,
    required this.smoothedSpeedKmh,
    required this.heading,
    required this.timestamp,
    this.isValid = true,
    this.rejectionReason = '',
  });
}

class GpsValidatorAndSmoother {
  final double maxAllowedAccuracyMeters;
  final double maxAllowedSpeedMps; // e.g., 33 m/s (~120 km/h)
  final double smoothingWeightAlpha; // Weight for new sample (0.0 to 1.0)

  RawGpsSample? _lastValidSample;
  double? _smoothedLat;
  double? _smoothedLon;
  double? _smoothedSpeedMps;

  GpsValidatorAndSmoother({
    this.maxAllowedAccuracyMeters = 50.0,
    this.maxAllowedSpeedMps = 35.0, // 126 km/h
    this.smoothingWeightAlpha = 0.65,
  });

  /// Validates and filters a raw GPS sample
  FilteredGpsPosition processSample(RawGpsSample sample) {
    // 1. Basic coordinate range validation
    if (sample.latitude < -90.0 || sample.latitude > 90.0 ||
        sample.longitude < -180.0 || sample.longitude > 180.0) {
      return FilteredGpsPosition(
        latitude: sample.latitude,
        longitude: sample.longitude,
        smoothedSpeedKmh: 0.0,
        heading: sample.heading,
        timestamp: sample.timestamp,
        isValid: false,
        rejectionReason: 'Invalid latitude or longitude values',
      );
    }

    // 2. Accuracy threshold check
    if (sample.accuracy > maxAllowedAccuracyMeters) {
      return FilteredGpsPosition(
        latitude: sample.latitude,
        longitude: sample.longitude,
        smoothedSpeedKmh: 0.0,
        heading: sample.heading,
        timestamp: sample.timestamp,
        isValid: false,
        rejectionReason: 'Poor GPS accuracy (${sample.accuracy.toStringAsFixed(1)}m > ${maxAllowedAccuracyMeters}m)',
      );
    }

    // 3. Improbable jump detection if last valid sample exists
    if (_lastValidSample != null) {
      final elapsedSeconds = sample.timestamp.difference(_lastValidSample!.timestamp).inMilliseconds / 1000.0;

      // Handle out-of-order or duplicate timestamps
      if (elapsedSeconds <= 0.05) {
        return FilteredGpsPosition(
          latitude: _smoothedLat ?? sample.latitude,
          longitude: _smoothedLon ?? sample.longitude,
          smoothedSpeedKmh: (_smoothedSpeedMps ?? 0.0) * 3.6,
          heading: sample.heading,
          timestamp: sample.timestamp,
          isValid: false,
          rejectionReason: 'Duplicate or out-of-order GPS timestamp',
        );
      }

      final jumpMeters = Haversine.distanceMeters(
        _lastValidSample!.latitude, _lastValidSample!.longitude,
        sample.latitude, sample.longitude,
      );

      final impliedSpeedMps = jumpMeters / elapsedSeconds;

      if (impliedSpeedMps > maxAllowedSpeedMps) {
        return FilteredGpsPosition(
          latitude: _smoothedLat ?? sample.latitude,
          longitude: _smoothedLon ?? sample.longitude,
          smoothedSpeedKmh: (_smoothedSpeedMps ?? 0.0) * 3.6,
          heading: sample.heading,
          timestamp: sample.timestamp,
          isValid: false,
          rejectionReason: 'Improbable teleportation jump (${impliedSpeedMps.toStringAsFixed(1)} m/s exceeds max ${maxAllowedSpeedMps} m/s)',
        );
      }
    }

    // 4. Determine effective speed (Direct Doppler speed or derived from delta-distance / delta-time)
    double effectiveSpeedMps = sample.speed;
    if (effectiveSpeedMps <= 0.0 && _lastValidSample != null) {
      final elapsedSeconds = math.max(0.5, sample.timestamp.difference(_lastValidSample!.timestamp).inMilliseconds / 1000.0);
      final deltaMeters = HaversineCalculator.distanceBetween(
        _lastValidSample!.latitude, _lastValidSample!.longitude,
        sample.latitude, sample.longitude,
      );
      if (deltaMeters < 2.0) {
        effectiveSpeedMps = 0.0; // Stationary
      } else {
        effectiveSpeedMps = math.min(maxAllowedSpeedMps, deltaMeters / elapsedSeconds);
      }
    }

    // 5. Smooth coordinates and speed via Exponential Moving Average (EMA)
    if (_smoothedLat == null || _smoothedLon == null) {
      _smoothedLat = sample.latitude;
      _smoothedLon = sample.longitude;
      _smoothedSpeedMps = math.max(0.0, effectiveSpeedMps);
    } else {
      _smoothedLat = (smoothingWeightAlpha * sample.latitude) + ((1 - smoothingWeightAlpha) * _smoothedLat!);
      _smoothedLon = (smoothingWeightAlpha * sample.longitude) + ((1 - smoothingWeightAlpha) * _smoothedLon!);
      _smoothedSpeedMps = (0.65 * math.max(0.0, effectiveSpeedMps)) + (0.35 * (_smoothedSpeedMps ?? 0.0));
    }

    _lastValidSample = sample;

    return FilteredGpsPosition(
      latitude: _smoothedLat!,
      longitude: _smoothedLon!,
      smoothedSpeedKmh: math.max(0.0, (_smoothedSpeedMps ?? 0.0) * 3.6),
      heading: sample.heading,
      timestamp: sample.timestamp,
      isValid: true,
    );
  }

  void reset() {
    _lastValidSample = null;
    _smoothedLat = null;
    _smoothedLon = null;
    _smoothedSpeedMps = null;
  }
}

