import 'haversine.dart';

enum GeofenceState {
  far,
  approaching,
  arrived,
  departed,
}

class GeofenceEvent {
  final String stopId;
  final String stopName;
  final GeofenceState state;
  final double distanceMeters;
  final DateTime timestamp;

  const GeofenceEvent({
    required this.stopId,
    required this.stopName,
    required this.state,
    required this.distanceMeters,
    required this.timestamp,
  });
}

class GeofenceDetector {
  final double approachThresholdMeters;
  final double arrivalThresholdMeters;
  final double departureThresholdMeters; // Arrival threshold + hysteresis margin

  // Track state per stop to enforce single-fire transitions
  final Map<String, GeofenceState> _stopStates = {};
  final Set<String> _firedApproachingAlerts = {};
  final Set<String> _firedArrivalAlerts = {};
  final Set<String> _firedDepartureAlerts = {};

  GeofenceDetector({
    this.approachThresholdMeters = 1500.0,
    this.arrivalThresholdMeters = 60.0,
    this.departureThresholdMeters = 100.0,
  });

  /// Evaluates vehicle position against a stop and returns a GeofenceEvent if a state transition occurs
  GeofenceEvent? evaluateStop({
    required String stopId,
    required String stopName,
    required double stopLatitude,
    required double stopLongitude,
    required double busLatitude,
    required double busLongitude,
  }) {
    final distance = Haversine.distanceMeters(
      busLatitude, busLongitude,
      stopLatitude, stopLongitude,
    );

    final previousState = _stopStates[stopId] ?? GeofenceState.far;
    GeofenceState newState = previousState;

    if (distance <= arrivalThresholdMeters) {
      newState = GeofenceState.arrived;
    } else if (previousState == GeofenceState.arrived && distance > departureThresholdMeters) {
      newState = GeofenceState.departed;
    } else if (previousState == GeofenceState.far && distance <= approachThresholdMeters) {
      newState = GeofenceState.approaching;
    }

    _stopStates[stopId] = newState;

    // Check if new event should be fired (Anti-spam protection)
    if (newState == GeofenceState.approaching && !_firedApproachingAlerts.contains(stopId)) {
      _firedApproachingAlerts.add(stopId);
      return GeofenceEvent(
        stopId: stopId,
        stopName: stopName,
        state: GeofenceState.approaching,
        distanceMeters: distance,
        timestamp: DateTime.now(),
      );
    }

    if (newState == GeofenceState.arrived && !_firedArrivalAlerts.contains(stopId)) {
      _firedArrivalAlerts.add(stopId);
      return GeofenceEvent(
        stopId: stopId,
        stopName: stopName,
        state: GeofenceState.arrived,
        distanceMeters: distance,
        timestamp: DateTime.now(),
      );
    }

    if (newState == GeofenceState.departed && !_firedDepartureAlerts.contains(stopId)) {
      _firedDepartureAlerts.add(stopId);
      return GeofenceEvent(
        stopId: stopId,
        stopName: stopName,
        state: GeofenceState.departed,
        distanceMeters: distance,
        timestamp: DateTime.now(),
      );
    }

    return null; // No transition or already notified
  }

  void resetTripState() {
    _stopStates.clear();
    _firedApproachingAlerts.clear();
    _firedArrivalAlerts.clear();
    _firedDepartureAlerts.clear();
  }
}

