import 'dart:async';
import 'dart:math' as math;
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/trip_model.dart';
import '../constants/app_constants.dart';
import '../algorithms/haversine.dart';

class SimulationService {
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal() {
    _initializeSeedData();
  }

  Timer? _simulationTimer;
  bool _isSimulationActive = false;
  bool get isSimulationActive => _isSimulationActive;

  final _fleetController = StreamController<List<BusModel>>.broadcast();
  Stream<List<BusModel>> get fleetStream => _fleetController.stream;

  final Map<String, int> _busWaypointIndices = {};
  final Map<String, double> _busSpeeds = {};

  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  List<TripModel> _trips = [];

  List<BusModel> get buses => _buses;
  List<RouteModel> get routes => _routes;
  List<TripModel> get trips => _trips;

  void _initializeSeedData() {
    // 5 Comprehensive Routes with Real Geodesic Waypoints (Kakinada - Surampalem College Corridor)
    _routes = [
      RouteModel(
        id: 'route_01',
        routeCode: 'R-01',
        routeName: 'Kakinada City Express',
        startLocation: 'Bhanugudi Junction',
        endLocation: 'Campus Central Terminal',
        totalDistanceKm: 28.5,
        estimatedDurationMinutes: 45,
        stops: [
          const StopModel(id: 'stop_01_01', name: 'Bhanugudi Junction', latitude: 16.9604, longitude: 82.2381, sequenceOrder: 1, scheduledPickupTime: '07:15 AM', registeredStudentCount: 8),
          const StopModel(id: 'stop_01_02', name: 'Main Road / Cinema Hall', latitude: 16.9850, longitude: 82.2220, sequenceOrder: 2, scheduledPickupTime: '07:25 AM', registeredStudentCount: 12),
          const StopModel(id: 'stop_01_03', name: 'Madhavapatnam Bypass', latitude: 17.0180, longitude: 82.1850, sequenceOrder: 3, scheduledPickupTime: '07:38 AM', registeredStudentCount: 9),
          const StopModel(id: 'stop_01_04', name: 'Samalkot Flyover', latitude: 17.0520, longitude: 82.1380, sequenceOrder: 4, scheduledPickupTime: '07:48 AM', registeredStudentCount: 11),
          const StopModel(id: 'stop_01_05', name: 'Aditya Campus Terminal', latitude: AppConstants.collegeLatitude, longitude: AppConstants.collegeLongitude, sequenceOrder: 5, scheduledPickupTime: '08:05 AM', registeredStudentCount: 0),
        ],
        polylineWaypoints: const [
          LatLngPoint(16.9604, 82.2381),
          LatLngPoint(16.9720, 82.2310),
          LatLngPoint(16.9850, 82.2220),
          LatLngPoint(17.0010, 82.2030),
          LatLngPoint(17.0180, 82.1850),
          LatLngPoint(17.0350, 82.1620),
          LatLngPoint(17.0520, 82.1380),
          LatLngPoint(17.0710, 82.1020),
          LatLngPoint(17.0850, 82.0800),
          LatLngPoint(AppConstants.collegeLatitude, AppConstants.collegeLongitude),
        ],
      ),
      RouteModel(
        id: 'route_02',
        routeCode: 'R-02',
        routeName: 'Rajahmundry Direct Line',
        startLocation: 'Kotipalli Bus Stand',
        endLocation: 'Campus Central Terminal',
        totalDistanceKm: 34.2,
        estimatedDurationMinutes: 52,
        stops: [
          const StopModel(id: 'stop_02_01', name: 'Kotipalli Stand', latitude: 17.0005, longitude: 81.7770, sequenceOrder: 1, scheduledPickupTime: '07:10 AM', registeredStudentCount: 10),
          const StopModel(id: 'stop_02_02', name: 'Morampudi Junction', latitude: 17.0150, longitude: 81.8020, sequenceOrder: 2, scheduledPickupTime: '07:22 AM', registeredStudentCount: 14),
          const StopModel(id: 'stop_02_03', name: 'Rajanagaram Center', latitude: 17.0820, longitude: 81.9050, sequenceOrder: 3, scheduledPickupTime: '07:38 AM', registeredStudentCount: 8),
          const StopModel(id: 'stop_02_04', name: 'Aditya Campus Terminal', latitude: AppConstants.collegeLatitude, longitude: AppConstants.collegeLongitude, sequenceOrder: 4, scheduledPickupTime: '08:02 AM', registeredStudentCount: 0),
        ],
        polylineWaypoints: const [
          LatLngPoint(17.0005, 81.7770),
          LatLngPoint(17.0150, 81.8020),
          LatLngPoint(17.0450, 81.8500),
          LatLngPoint(17.0820, 81.9050),
          LatLngPoint(17.0890, 81.9800),
          LatLngPoint(AppConstants.collegeLatitude, AppConstants.collegeLongitude),
        ],
      ),
      RouteModel(
        id: 'route_03',
        routeCode: 'R-03',
        routeName: 'Samalkot Railway Junction',
        startLocation: 'Samalkot Station',
        endLocation: 'Campus Central Terminal',
        totalDistanceKm: 14.8,
        estimatedDurationMinutes: 28,
        stops: [
          const StopModel(id: 'stop_03_01', name: 'Station Road', latitude: 17.0515, longitude: 82.1680, sequenceOrder: 1, scheduledPickupTime: '07:35 AM', registeredStudentCount: 6),
          const StopModel(id: 'stop_03_02', name: 'RTC Complex', latitude: 17.0580, longitude: 82.1520, sequenceOrder: 2, scheduledPickupTime: '07:44 AM', registeredStudentCount: 15),
          const StopModel(id: 'stop_03_03', name: 'Aditya Campus Terminal', latitude: AppConstants.collegeLatitude, longitude: AppConstants.collegeLongitude, sequenceOrder: 3, scheduledPickupTime: '08:03 AM', registeredStudentCount: 0),
        ],
        polylineWaypoints: const [
          LatLngPoint(17.0515, 82.1680),
          LatLngPoint(17.0580, 82.1520),
          LatLngPoint(17.0720, 82.1100),
          LatLngPoint(AppConstants.collegeLatitude, AppConstants.collegeLongitude),
        ],
      ),
      RouteModel(
        id: 'route_04',
        routeCode: 'R-04',
        routeName: 'Peddapuram Shuttle',
        startLocation: 'Peddapuram Clock Tower',
        endLocation: 'Campus Central Terminal',
        totalDistanceKm: 11.2,
        estimatedDurationMinutes: 22,
        stops: [
          const StopModel(id: 'stop_04_01', name: 'Clock Tower', latitude: 17.0780, longitude: 82.1350, sequenceOrder: 1, scheduledPickupTime: '07:40 AM', registeredStudentCount: 12),
          const StopModel(id: 'stop_04_02', name: 'Polytechnic Circle', latitude: 17.0840, longitude: 82.1050, sequenceOrder: 2, scheduledPickupTime: '07:50 AM', registeredStudentCount: 9),
          const StopModel(id: 'stop_04_03', name: 'Aditya Campus Terminal', latitude: AppConstants.collegeLatitude, longitude: AppConstants.collegeLongitude, sequenceOrder: 3, scheduledPickupTime: '08:02 AM', registeredStudentCount: 0),
        ],
        polylineWaypoints: const [
          LatLngPoint(17.0780, 82.1350),
          LatLngPoint(17.0840, 82.1050),
          LatLngPoint(AppConstants.collegeLatitude, AppConstants.collegeLongitude),
        ],
      ),
      RouteModel(
        id: 'route_05',
        routeCode: 'R-05',
        routeName: 'Annavaram Rural Route',
        startLocation: 'Annavaram Hill Gate',
        endLocation: 'Campus Central Terminal',
        totalDistanceKm: 38.6,
        estimatedDurationMinutes: 55,
        stops: [
          const StopModel(id: 'stop_05_01', name: 'Hill Gate', latitude: 17.2800, longitude: 82.4050, sequenceOrder: 1, scheduledPickupTime: '07:05 AM', registeredStudentCount: 7),
          const StopModel(id: 'stop_05_02', name: 'Kathipudi Junction', latitude: 17.2400, longitude: 82.3400, sequenceOrder: 2, scheduledPickupTime: '07:22 AM', registeredStudentCount: 11),
          const StopModel(id: 'stop_05_03', name: 'Prathipadu Center', latitude: 17.1850, longitude: 82.2150, sequenceOrder: 3, scheduledPickupTime: '07:38 AM', registeredStudentCount: 8),
          const StopModel(id: 'stop_05_04', name: 'Aditya Campus Terminal', latitude: AppConstants.collegeLatitude, longitude: AppConstants.collegeLongitude, sequenceOrder: 4, scheduledPickupTime: '08:00 AM', registeredStudentCount: 0),
        ],
        polylineWaypoints: const [
          LatLngPoint(17.2800, 82.4050),
          LatLngPoint(17.2400, 82.3400),
          LatLngPoint(17.1850, 82.2150),
          LatLngPoint(17.1250, 82.1400),
          LatLngPoint(AppConstants.collegeLatitude, AppConstants.collegeLongitude),
        ],
      ),
    ];

    // 5 Operating Buses with realistic drivers and capacities
    _buses = [
      BusModel(
        id: 'bus_01',
        busNumber: 'Bus 12 (Express)',
        registrationPlate: 'AP-05-TJ-1012',
        totalCapacity: 52,
        occupiedSeats: 38,
        status: BusOperationalStatus.moving,
        assignedDriverId: 'driver_b1',
        assignedDriverName: 'M. S. Prasad',
        assignedRouteId: 'route_01',
        assignedRouteName: 'Kakinada City Express',
        liveLocation: BusLiveLocation(
          latitude: 17.0180,
          longitude: 82.1850,
          speedKmh: 36.5,
          heading: 315.0,
          accuracyMeters: 4.5,
          timestamp: DateTime.now(),
          isSimulation: true,
        ),
      ),
      BusModel(
        id: 'bus_02',
        busNumber: 'Bus 07',
        registrationPlate: 'AP-05-TJ-1007',
        totalCapacity: 50,
        occupiedSeats: 32,
        status: BusOperationalStatus.moving,
        assignedDriverId: 'driver_b2',
        assignedDriverName: 'K. Rambabu',
        assignedRouteId: 'route_02',
        assignedRouteName: 'Rajahmundry Direct Line',
        liveLocation: BusLiveLocation(
          latitude: 17.0450,
          longitude: 81.8500,
          speedKmh: 42.0,
          heading: 65.0,
          accuracyMeters: 5.0,
          timestamp: DateTime.now(),
          isSimulation: true,
        ),
      ),
      BusModel(
        id: 'bus_03',
        busNumber: 'Bus 24 (Shuttle)',
        registrationPlate: 'AP-05-TJ-1024',
        totalCapacity: 45,
        occupiedSeats: 41,
        status: BusOperationalStatus.stationary,
        assignedDriverId: 'driver_b3',
        assignedDriverName: 'N. Satyanarayana',
        assignedRouteId: 'route_03',
        assignedRouteName: 'Samalkot Railway Junction',
        liveLocation: BusLiveLocation(
          latitude: 17.0580,
          longitude: 82.1520,
          speedKmh: 0.0,
          heading: 280.0,
          accuracyMeters: 3.8,
          timestamp: DateTime.now(),
          isSimulation: true,
        ),
      ),
      BusModel(
        id: 'bus_04',
        busNumber: 'Bus 18',
        registrationPlate: 'AP-05-TJ-1018',
        totalCapacity: 48,
        occupiedSeats: 25,
        status: BusOperationalStatus.moving,
        assignedDriverId: 'driver_b4',
        assignedDriverName: 'P. Venkat Rao',
        assignedRouteId: 'route_04',
        assignedRouteName: 'Peddapuram Shuttle',
        liveLocation: BusLiveLocation(
          latitude: 17.0840,
          longitude: 82.1050,
          speedKmh: 31.0,
          heading: 250.0,
          accuracyMeters: 4.2,
          timestamp: DateTime.now(),
          isSimulation: true,
        ),
      ),
      BusModel(
        id: 'bus_05',
        busNumber: 'Bus 31 (Rural)',
        registrationPlate: 'AP-05-TJ-1031',
        totalCapacity: 50,
        occupiedSeats: 27,
        status: BusOperationalStatus.delayed,
        assignedDriverId: 'driver_b5',
        assignedDriverName: 'G. Appa Rao',
        assignedRouteId: 'route_05',
        assignedRouteName: 'Annavaram Rural Route',
        liveLocation: BusLiveLocation(
          latitude: 17.1850,
          longitude: 82.2150,
          speedKmh: 24.0,
          heading: 215.0,
          accuracyMeters: 6.0,
          timestamp: DateTime.now(),
          isSimulation: true,
        ),
      ),
    ];

    for (final bus in _buses) {
      _busWaypointIndices[bus.id] = 2; // Mid-route start
      _busSpeeds[bus.id] = 34.0;
    }
  }

  /// Starts realistic simulated GPS movement loop (updates every 3 seconds)
  void startSimulation() {
    if (_isSimulationActive) return;
    _isSimulationActive = true;

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _advanceBuses();
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isSimulationActive = false;
  }

  void _advanceBuses() {
    final updatedList = <BusModel>[];

    for (final bus in _buses) {
      // Don't move if bus is in breakdown or emergency
      if (bus.status == BusOperationalStatus.breakdown || bus.status == BusOperationalStatus.emergency) {
        updatedList.add(bus);
        continue;
      }

      final route = _routes.firstWhere(
        (r) => r.id == bus.assignedRouteId,
        orElse: () => _routes.first,
      );

      final waypoints = route.polylineWaypoints;
      int currIndex = _busWaypointIndices[bus.id] ?? 0;

      // Advance waypoint index
      if (currIndex < waypoints.length - 1) {
        currIndex++;
      } else {
        currIndex = 0; // Loop simulation for continuous demonstration
      }
      _busWaypointIndices[bus.id] = currIndex;

      final targetPt = waypoints[currIndex];
      // Add slight jitter for realistic sensor noise
      final random = math.Random();
      final jitterLat = (random.nextDouble() - 0.5) * 0.0001;
      final jitterLng = (random.nextDouble() - 0.5) * 0.0001;

      final double speed = (30.0 + random.nextInt(15)).toDouble();
      _busSpeeds[bus.id] = speed;

      final newLoc = BusLiveLocation(
        latitude: targetPt.latitude + jitterLat,
        longitude: targetPt.longitude + jitterLng,
        speedKmh: speed,
        heading: (currIndex * 35.0) % 360.0,
        accuracyMeters: 3.5 + random.nextDouble() * 2.0,
        timestamp: DateTime.now(),
        isSimulation: true,
      );

      updatedList.add(bus.copyWith(
        liveLocation: newLoc,
        status: speed > 2.0 ? BusOperationalStatus.moving : BusOperationalStatus.stationary,
      ));
    }

    _buses = updatedList;
    _fleetController.add(_buses);
  }

  /// Triggers a simulated breakdown incident for demonstration & research testing
  void injectBreakdown(String busId) {
    _buses = _buses.map((b) {
      if (b.id == busId) {
        return b.copyWith(
          status: BusOperationalStatus.breakdown,
          liveLocation: BusLiveLocation(
            latitude: b.liveLocation?.latitude ?? 17.0180,
            longitude: b.liveLocation?.longitude ?? 82.1850,
            speedKmh: 0.0,
            heading: b.liveLocation?.heading ?? 0.0,
            accuracyMeters: 4.0,
            timestamp: DateTime.now(),
            isSimulation: true,
          ),
        );
      }
      return b;
    }).toList();
    _fleetController.add(_buses);
  }

  /// Triggers a simulated SOS emergency for testing
  void injectEmergency(String busId) {
    _buses = _buses.map((b) {
      if (b.id == busId) {
        return b.copyWith(
          status: BusOperationalStatus.emergency,
        );
      }
      return b;
    }).toList();
    _fleetController.add(_buses);
  }

  void resolveIncident(String busId) {
    _buses = _buses.map((b) {
      if (b.id == busId) {
        return b.copyWith(
          status: BusOperationalStatus.moving,
        );
      }
      return b;
    }).toList();
    _fleetController.add(_buses);
  }
}

