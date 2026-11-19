class AppConstants {
  static const String appName = "Smart Campus Transport";
  static const String appVersion = "1.0.0";
  static const String collegeName = "Aditya University & Engineering Campuses";

  // Firebase Realtime Database Live URL
  static const String firebaseRtdbUrl = "https://gps-tracking-b76d8-default-rtdb.firebaseio.com";

  // Coordinates of College Main Gate / Transport Depot
  static const double collegeLatitude = 17.0911;
  static const double collegeLongitude = 82.0673;

  // Real-Time GPS Tracking Parameters
  static const int normalGpsIntervalMs = 3000;    // 3 seconds target
  static const int stationaryGpsIntervalMs = 10000; // 10 seconds when stationary
  static const double maxPlausibleSpeedKmh = 120.0;
  static const double minAcceptableAccuracyMeters = 50.0;
  static const double maxPlausibleJumpMetersPerSecond = 40.0;

  // Geofencing and Stop Detection
  static const double stopProximityRadiusMeters = 80.0;
  static const double approachingAlertDistanceMeters = 1500.0; // 1.5 km alert
  static const double stopArrivalRadiusMeters = 40.0;

  // Map Tile Sources
  // Free, high performance vector tile endpoint
  static const String openFreeMapStyle = "https://tiles.openfreemap.org/styles/liberty";
  static const String osmRasterTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

  // Demo Accounts
  static const String demoAdminEmail = "admin@campus.edu";
  static const String demoCoordinatorEmail = "controlroom@campus.edu";
  static const String demoDriverEmail = "driver.b1@campus.edu";
  static const String demoStudentEmail = "student1@campus.edu";
  static const String demoParentEmail = "parent1@campus.edu";

  // Firebase RTDB Paths
  static const String pathLiveLocations = "liveLocations";
  static const String pathActiveTrips = "activeTrips";
  static const String pathBusPresence = "busPresence";
  static const String pathActiveIncidents = "activeIncidents";
  static const String pathLiveStatuses = "liveTripStatuses";
}

