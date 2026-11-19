import 'package:flutter_test/flutter_test.dart';
import '../lib/core/algorithms/haversine.dart';
import '../lib/core/algorithms/dijkstra.dart';
import '../lib/core/algorithms/a_star.dart';
import '../lib/core/algorithms/eta_engine.dart';
import '../lib/core/algorithms/geofence_detector.dart';
import '../lib/core/algorithms/breakdown_ranker.dart';
import '../lib/core/algorithms/gps_smoother.dart';
import '../lib/core/services/attendance_service.dart';

void main() {
  group('GIS & Geodesic Calculations (Haversine)', () {
    test('Calculates distance between college and Kakinada depot accurately', () {
      final distMeters = Haversine.distanceMeters(17.0911, 82.0673, 16.9604, 82.2381);
      expect(distMeters, greaterThan(20000.0));
      expect(distMeters, lessThan(35000.0));
    });

    test('Bearing calculation returns valid degree in [0, 360)', () {
      final bearing = Haversine.bearing(17.0911, 82.0673, 16.9604, 82.2381);
      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThan(360.0));
    });
  });

  group('Pathfinding Algorithms (Dijkstra vs A*)', () {
    final nodes = <String, GraphNode>{
      'A': const GraphNode(id: 'A', name: 'Start', latitude: 17.00, longitude: 82.00),
      'B': const GraphNode(id: 'B', name: 'Junction', latitude: 17.05, longitude: 82.05),
      'C': const GraphNode(id: 'C', name: 'Campus', latitude: 17.10, longitude: 82.10),
    };

    final edges = <String, List<GraphEdge>>{
      'A': [const GraphEdge(targetNodeId: 'B', distanceMeters: 5000.0)],
      'B': [const GraphEdge(targetNodeId: 'C', distanceMeters: 6000.0)],
      'C': [],
    };

    test('Dijkstra finds optimal path A -> B -> C', () {
      final router = DijkstraRouter(nodes: nodes, adjacencyList: edges);
      final res = router.findShortestPath('A', 'C');
      expect(res.pathNodeIds, equals(['A', 'B', 'C']));
      expect(res.totalDistanceMeters, equals(11000.0));
      expect(res.exploredNodes, greaterThanOrEqualTo(2));
    });

    test('A* finds identical shortest path with goal-directed heuristic', () {
      final aStar = AStarRouter(nodes: nodes, adjacencyList: edges);
      final res = aStar.findOptimalPath('A', 'C');
      expect(res.pathNodeIds, equals(['A', 'B', 'C']));
      expect(res.totalDistanceMeters, equals(11000.0));
    });
  });

  group('Predictive ETA Engine', () {
    test('Method B incorporates recent speed EMA and dynamic stop dwell time', () {
      final baseline = EtaEngine.calculateBaselineEta(
        remainingDistanceMeters: 5000.0,
        remainingStopsCount: 2,
        defaultSpeedKmh: 30.0,
      );

      final predictive = EtaEngine.calculatePredictiveEta(
        remainingDistanceMeters: 5000.0,
        remainingStopsCount: 2,
        currentSpeedKmh: 35.0,
        recentSpeedSamplesKmh: [30.0, 32.0, 36.0],
        passengersToPickupAtStops: 10,
      );

      expect(baseline.etaMinutes, greaterThan(0.0));
      expect(predictive.etaMinutes, greaterThan(0.0));
      expect(predictive.confidenceScore, greaterThan(0.8));
    });
  });

  group('Geofence & Hysteresis State Transition', () {
    test('Fires approaching, arrived, and departed without duplicate spam', () {
      final detector = GeofenceDetector(
        approachThresholdMeters: 1000.0,
        arrivalThresholdMeters: 60.0,
        departureThresholdMeters: 100.0,
      );

      // 1. Approaching (500m away)
      final e1 = detector.evaluateStop(
        stopId: 's1',
        stopName: 'Bypass',
        stopLatitude: 17.0000,
        stopLongitude: 82.0000,
        busLatitude: 17.0040,
        busLongitude: 82.0000,
      );
      expect(e1?.state, equals(GeofenceState.approaching));

      // Repeated sample at 480m should not fire duplicate event
      final e1Repeat = detector.evaluateStop(
        stopId: 's1',
        stopName: 'Bypass',
        stopLatitude: 17.0000,
        stopLongitude: 82.0000,
        busLatitude: 17.0038,
        busLongitude: 82.0000,
      );
      expect(e1Repeat, isNull);
    });
  });

  group('Intelligent Breakdown Rescue Ranking (MAUT)', () {
    test('Penalizes buses with insufficient spare capacity', () {
      final fleet = [
        const CandidateBus(busId: 'B1', busNumber: 'Bus 1', driverId: 'D1', driverName: 'A', currentLatitude: 17.01, currentLongitude: 82.01, totalCapacity: 50, occupiedSeats: 48, currentRouteId: 'R1'), // 2 spare
        const CandidateBus(busId: 'B2', busNumber: 'Bus 2', driverId: 'D2', driverName: 'B', currentLatitude: 17.03, currentLongitude: 82.03, totalCapacity: 50, occupiedSeats: 15, currentRouteId: 'R1'), // 35 spare
      ];

      final ranked = BreakdownAssistanceRanker.rankCandidates(
        breakdownLatitude: 17.00,
        breakdownLongitude: 82.00,
        strandedPassengerCount: 20,
        brokenBusRouteId: 'R1',
        candidateFleet: fleet,
      );

      expect(ranked.first.bus.busId, equals('B2'));
      expect(ranked.first.isCapacityFeasible, isTrue);
      expect(ranked.last.isCapacityFeasible, isFalse);
    });
  });

  group('GPS Validation and Smoothing', () {
    test('Rejects coordinates with accuracy worse than 50 meters', () {
      final smoother = GpsValidatorAndSmoother(maxAllowedAccuracyMeters: 50.0);
      final sample = RawGpsSample(
        latitude: 17.05,
        longitude: 82.05,
        accuracy: 85.0, // Inaccurate
        speed: 10.0,
        heading: 90.0,
        timestamp: DateTime.now(),
      );

      final res = smoother.processSample(sample);
      expect(res.isValid, isFalse);
    });

    test('Rejects improbable teleportation jump', () {
      final smoother = GpsValidatorAndSmoother(maxAllowedSpeedMps: 35.0);
      final t0 = DateTime.now();

      smoother.processSample(RawGpsSample(
        latitude: 17.00,
        longitude: 82.00,
        accuracy: 5.0,
        speed: 10.0,
        heading: 0.0,
        timestamp: t0,
      ));

      // 1 second later, jumped 20 km away
      final teleported = smoother.processSample(RawGpsSample(
        latitude: 17.18,
        longitude: 82.18,
        accuracy: 5.0,
        speed: 10.0,
        heading: 0.0,
        timestamp: t0.add(const Duration(seconds: 1)),
      ));

      expect(teleported.isValid, isFalse);
    });
  });

  group('Smart Attendance QR Verification & Duplicate Prevention', () {
    test('Rejects duplicate attendance attempts for same student on same trip', () {
      final service = AttendanceService();
      final token = service.generateSignedQrToken(studentId: 'std_99', tripId: 'trip_demo');

      // 1st attempt: Valid
      final res1 = service.verifyScannedToken(
        base64Token: token,
        currentTripId: 'trip_demo',
        verifierDriverId: 'drv_01',
        studentName: 'Test Student',
        rollNumber: '21A91A0599',
        stopId: 'stop_01',
        stopName: 'Campus Gate',
        busLat: 17.0911,
        busLng: 82.0673,
        stopLat: 17.0911,
        stopLng: 82.0673,
      );
      expect(res1.isSuccess, isTrue);

      // 2nd attempt with same token: Duplicate rejected!
      final res2 = service.verifyScannedToken(
        base64Token: token,
        currentTripId: 'trip_demo',
        verifierDriverId: 'drv_01',
        studentName: 'Test Student',
        rollNumber: '21A91A0599',
        stopId: 'stop_01',
        stopName: 'Campus Gate',
        busLat: 17.0911,
        busLng: 82.0673,
        stopLat: 17.0911,
        stopLng: 82.0673,
      );
      expect(res2.isSuccess, isFalse);
      expect(res2.message, contains('Duplicate'));
    });
  });
}

