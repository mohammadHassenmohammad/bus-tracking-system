import 'dart:math' as math;
import 'haversine.dart';

class CandidateBus {
  final String busId;
  final String busNumber;
  final String driverId;
  final String driverName;
  final double currentLatitude;
  final double currentLongitude;
  final int totalCapacity;
  final int occupiedSeats;
  final String currentRouteId;
  final String operationalStatus; // 'active', 'paused', 'idle', 'in_breakdown'
  final bool isAuthorizedForEmergency;

  const CandidateBus({
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.driverName,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.totalCapacity,
    required this.occupiedSeats,
    required this.currentRouteId,
    this.operationalStatus = 'active',
    this.isAuthorizedForEmergency = true,
  });

  int get spareCapacity => math.max(0, totalCapacity - occupiedSeats);
}

class RankedAssistanceCandidate {
  final CandidateBus bus;
  final double distanceMeters;
  final double estimatedArrivalMinutes;
  final double suitabilityScore; // 0.0 to 100.0
  final bool isCapacityFeasible;
  final String compatibilityReason;

  const RankedAssistanceCandidate({
    required this.bus,
    required this.distanceMeters,
    required this.estimatedArrivalMinutes,
    required this.suitabilityScore,
    required this.isCapacityFeasible,
    required this.compatibilityReason,
  });
}

class BreakdownAssistanceRanker {
  // Weights summing to 1.0
  static const double weightDistance = 0.30;
  static const double weightTime = 0.25;
  static const double weightCapacity = 0.30;
  static const double weightRouteCompatibility = 0.15;

  static const double maxEvaluationRadiusMeters = 25000.0; // 25 km max candidate radius
  static const double maxEvaluationTimeMinutes = 45.0;

  /// Ranks candidates for breakdown rescue based on multi-attribute utility theory (MAUT)
  static List<RankedAssistanceCandidate> rankCandidates({
    required double breakdownLatitude,
    required double breakdownLongitude,
    required int strandedPassengerCount,
    required String brokenBusRouteId,
    required List<CandidateBus> candidateFleet,
  }) {
    final scoredList = <RankedAssistanceCandidate>[];

    for (final candidate in candidateFleet) {
      // 1. Operational filter: Must be authorized and operational
      if (!candidate.isAuthorizedForEmergency || candidate.operationalStatus != 'active') {
        continue;
      }

      // 2. Geodesic distance to breakdown site
      final distanceM = Haversine.distanceMeters(
        breakdownLatitude, breakdownLongitude,
        candidate.currentLatitude, candidate.currentLongitude,
      );

      // Filter buses too far away
      if (distanceM > maxEvaluationRadiusMeters) continue;

      // 3. Estimated ETA assuming average rescue speed of 35 km/h
      final etaMinutes = (distanceM / (35.0 * 1000.0 / 60.0));

      // 4. Capacity constraint check
      final isCapacitySufficient = candidate.spareCapacity >= strandedPassengerCount;

      // 5. Route similarity factor (1.0 if identical corridor, 0.7 if converging, 0.4 if divergent)
      double routeCompatibility = 0.4;
      if (candidate.currentRouteId == brokenBusRouteId) {
        routeCompatibility = 1.0;
      } else if (candidate.currentRouteId.startsWith(brokenBusRouteId.substring(0, math.min(2, brokenBusRouteId.length)))) {
        routeCompatibility = 0.75;
      }

      // 6. Multi-attribute utility score calculation
      final normalizedDistanceScore = math.max(0.0, 1.0 - (distanceM / maxEvaluationRadiusMeters));
      final normalizedTimeScore = math.max(0.0, 1.0 - (etaMinutes / maxEvaluationTimeMinutes));
      final spareSeatsRatio = candidate.totalCapacity > 0
          ? math.min(1.0, candidate.spareCapacity / candidate.totalCapacity)
          : 0.0;

      double utilityScore = (normalizedDistanceScore * weightDistance) +
          (normalizedTimeScore * weightTime) +
          (spareSeatsRatio * weightCapacity) +
          (routeCompatibility * weightRouteCompatibility);

      // Penalize heavily if capacity is insufficient
      if (!isCapacitySufficient) {
        utilityScore *= 0.25; // 75% penalty for partial capacity
      }

      final finalScore = (utilityScore * 100.0).clamp(0.0, 100.0);

      String reason = isCapacitySufficient
          ? "Sufficient capacity (${candidate.spareCapacity} seats available)"
          : "Insufficient capacity: only ${candidate.spareCapacity} seats for $strandedPassengerCount students";

      if (candidate.currentRouteId == brokenBusRouteId) {
        reason += " | Same route corridor";
      }

      scoredList.add(RankedAssistanceCandidate(
        bus: candidate,
        distanceMeters: distanceM,
        estimatedArrivalMinutes: etaMinutes,
        suitabilityScore: finalScore,
        isCapacityFeasible: isCapacitySufficient,
        compatibilityReason: reason,
      ));
    }

    // Sort descending by suitability score
    scoredList.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));
    return scoredList;
  }
}

