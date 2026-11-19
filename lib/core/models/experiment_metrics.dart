class EtaComparisonMetric {
  final int sampleId;
  final double groundTruthArrivalMinutes;
  final double baselinePredictionMinutes;
  final double predictivePredictionMinutes;
  final double baselineAbsoluteError;
  final double predictiveAbsoluteError;

  const EtaComparisonMetric({
    required this.sampleId,
    required this.groundTruthArrivalMinutes,
    required this.baselinePredictionMinutes,
    required this.predictivePredictionMinutes,
    required this.baselineAbsoluteError,
    required this.predictiveAbsoluteError,
  });
}

class RoutingComparisonMetric {
  final String sourceNode;
  final String targetNode;
  final double dijkstraRuntimeMicros;
  final int dijkstraExploredNodes;
  final double dijkstraDistanceMeters;
  final double aStarRuntimeMicros;
  final int aStarExploredNodes;
  final double aStarDistanceMeters;

  const RoutingComparisonMetric({
    required this.sourceNode,
    required this.targetNode,
    required this.dijkstraRuntimeMicros,
    required this.dijkstraExploredNodes,
    required this.dijkstraDistanceMeters,
    required this.aStarRuntimeMicros,
    required this.aStarExploredNodes,
    required this.aStarDistanceMeters,
  });
}

class BreakdownRankingMetric {
  final int testCaseId;
  final int strandedPassengers;
  final String nearestBusId;
  final bool nearestBusFeasible;
  final double nearestBusEtaMinutes;
  final String capacityRankedBusId;
  final bool capacityRankedFeasible;
  final double capacityRankedEtaMinutes;

  const BreakdownRankingMetric({
    required this.testCaseId,
    required this.strandedPassengers,
    required this.nearestBusId,
    required this.nearestBusFeasible,
    required this.nearestBusEtaMinutes,
    required this.capacityRankedBusId,
    required this.capacityRankedFeasible,
    required this.capacityRankedEtaMinutes,
  });
}

class GpsIntervalMetric {
  final int intervalSeconds;
  final double averageLatencyMs;
  final double estimatedBandwidthKbPerHour;
  final double freshnessSeconds;
  final int dailyFirebaseWritesPerBus;

  const GpsIntervalMetric({
    required this.intervalSeconds,
    required this.averageLatencyMs,
    required this.estimatedBandwidthKbPerHour,
    required this.freshnessSeconds,
    required this.dailyFirebaseWritesPerBus,
  });
}

class AttendanceVerificationMetric {
  final int testTrialId;
  final bool isQrValid;
  final bool isWithinGeofence;
  final bool isDuplicate;
  final bool verificationAccepted;
  final String resultStatus;

  const AttendanceVerificationMetric({
    required this.testTrialId,
    required this.isQrValid,
    required this.isWithinGeofence,
    required this.isDuplicate,
    required this.verificationAccepted,
    required this.resultStatus,
  });
}

