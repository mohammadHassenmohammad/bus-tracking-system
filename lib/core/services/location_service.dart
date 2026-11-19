import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../algorithms/gps_smoother.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final GpsValidatorAndSmoother _smoother = GpsValidatorAndSmoother();
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<FilteredGpsPosition>.broadcast();
  Stream<FilteredGpsPosition> get locationStream => _locationController.stream;

  final List<RawGpsSample> _offlineBuffer = [];
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  /// Checks and requests necessary location permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Starts real-time GPS acquisition for active driver tracking
  Future<void> startLocationTracking({
    int intervalMs = 3000,
    int distanceFilterMeters = 2,
  }) async {
    if (_isTracking) return;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      // Permission not granted or running in test environment
      return;
    }

    _isTracking = true;
    _smoother.reset();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final sample = RawGpsSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );

      final filtered = _smoother.processSample(sample);
      if (filtered.isValid) {
        _locationController.add(filtered);
      }
    }, onError: (error) {
      // Handle sensor or GPS hardware errors gracefully
    });
  }

  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  void bufferOfflinePosition(RawGpsSample sample) {
    _offlineBuffer.add(sample);
  }

  List<RawGpsSample> flushOfflineBuffer() {
    final copy = List<RawGpsSample>.from(_offlineBuffer);
    _offlineBuffer.clear();
    return copy;
  }
}

