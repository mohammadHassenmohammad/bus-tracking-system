import 'dart:math' as math;

class EtaPrediction {
  final double etaMinutes;
  final double distanceRemainingMeters;
  final DateTime expectedArrivalTime;
  final double confidenceScore; // 0.0 to 1.0
  final String methodUsed; // 'Baseline' or 'Enhanced Predictive'
  final DateTime calculatedAt;

  const EtaPrediction({
    required this.etaMinutes,
    required this.distanceRemainingMeters,
    required this.expectedArrivalTime,
    required this.confidenceScore,
    required this.methodUsed,
    required this.calculatedAt,
  });

  String get formattedEta {
    if (etaMinutes < 1.0) return "Arriving now (< 1 min)";
    final mins = etaMinutes.round();
    return "$mins min${mins > 1 ? 's' : ''}";
  }
}

class EtaEngine {
  // Method A: Baseline ETA
  static EtaPrediction calculateBaselineEta({
    required double remainingDistanceMeters,
    required int remainingStopsCount,
    double defaultSpeedKmh = 30.0,
    double stopDwellSeconds = 45.0,
  }) {
    final now = DateTime.now();
    final speedMps = (defaultSpeedKmh * 1000.0) / 3600.0;
    final travelTimeSeconds = remainingDistanceMeters / math.max(speedMps, 1.0);
    final totalDwellSeconds = remainingStopsCount * stopDwellSeconds;
    final totalSeconds = travelTimeSeconds + totalDwellSeconds;
    final totalMinutes = totalSeconds / 60.0;

    return EtaPrediction(
      etaMinutes: totalMinutes,
      distanceRemainingMeters: remainingDistanceMeters,
      expectedArrivalTime: now.add(Duration(seconds: totalSeconds.round())),
      confidenceScore: 0.60,
      methodUsed: 'Baseline',
      calculatedAt: now,
    );
  }

  // Method B: Improved Multi-Factor Predictive ETA
  static EtaPrediction calculatePredictiveEta({
    required double remainingDistanceMeters,
    required int remainingStopsCount,
    required double currentSpeedKmh,
    required List<double> recentSpeedSamplesKmh,
    required int passengersToPickupAtStops,
    bool isOffRoute = false,
    double timeOfDayCongestionFactor = 1.15, // Peak morning/evening factor
    double nominalSpeedKmh = 32.0,
  }) {
    final now = DateTime.now();

    // 1. Calculate Exponential Moving Average (EMA) of recent speeds
    double emaSpeedKmh = nominalSpeedKmh;
    if (recentSpeedSamplesKmh.isNotEmpty) {
      const alpha = 0.4; // Weight for recent samples
      emaSpeedKmh = recentSpeedSamplesKmh.first;
      for (int i = 1; i < recentSpeedSamplesKmh.length; i++) {
        emaSpeedKmh = (alpha * recentSpeedSamplesKmh[i]) + ((1 - alpha) * emaSpeedKmh);
      }
    }

    // Blend current speed and EMA (smooth against brief red-light stops)
    final effectiveSpeedKmh = math.max(
      8.0, // Minimum crawler speed in congested urban traffic
      math.min(50.0, (0.6 * emaSpeedKmh) + (0.4 * math.max(currentSpeedKmh, 10.0))),
    );

    // Apply segment congestion multiplier
    final adjustedSpeedKmh = effectiveSpeedKmh / math.max(1.0, timeOfDayCongestionFactor);
    final speedMps = (adjustedSpeedKmh * 1000.0) / 3600.0;

    // 2. Dynamic dwell time per stop: base 30s + 3s per boarding student
    final dynamicDwellSeconds = (remainingStopsCount * 30.0) + (passengersToPickupAtStops * 3.0);

    // 3. Raw travel time
    double travelTimeSeconds = remainingDistanceMeters / speedMps;

    // 4. Off-route or detour penalty
    if (isOffRoute) {
      travelTimeSeconds *= 1.30; // 30% penalty for route re-alignment
    }

    final totalSeconds = travelTimeSeconds + dynamicDwellSeconds;
    final totalMinutes = totalSeconds / 60.0;

    // 5. Confidence scoring based on speed variance and route stability
    double confidence = 0.92;
    if (isOffRoute) confidence -= 0.25;
    if (currentSpeedKmh < 5.0) confidence -= 0.10; // Stuck in bottleneck
    if (recentSpeedSamplesKmh.length < 3) confidence -= 0.10; // Insufficient history

    return EtaPrediction(
      etaMinutes: math.max(0.5, totalMinutes),
      distanceRemainingMeters: remainingDistanceMeters,
      expectedArrivalTime: now.add(Duration(seconds: totalSeconds.round())),
      confidenceScore: math.max(0.3, math.min(0.99, confidence)),
      methodUsed: 'Enhanced Predictive',
      calculatedAt: now,
    );
  }
}

