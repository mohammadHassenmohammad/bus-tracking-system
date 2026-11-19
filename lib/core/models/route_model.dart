class StopModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final String scheduledPickupTime;
  final int registeredStudentCount;

  const StopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    required this.scheduledPickupTime,
    this.registeredStudentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequenceOrder': sequenceOrder,
      'scheduledPickupTime': scheduledPickupTime,
      'registeredStudentCount': registeredStudentCount,
    };
  }

  factory StopModel.fromMap(Map<String, dynamic> map, String id) {
    return StopModel(
      id: id,
      name: map['name'] ?? 'Stop',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      sequenceOrder: (map['sequenceOrder'] as num?)?.toInt() ?? 0,
      scheduledPickupTime: map['scheduledPickupTime'] ?? '07:30 AM',
      registeredStudentCount: (map['registeredStudentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TurnManeuverModel {
  final String id;
  final String type; // depart, turn_left, turn_right, continue, roundabout, arrive_stop, arrive_destination
  final String icon;
  final String streetName;
  final String instruction;
  final String voiceInstruction;
  final double latitude;
  final double longitude;
  final String? targetStopId;

  const TurnManeuverModel({
    required this.id,
    required this.type,
    required this.icon,
    required this.streetName,
    required this.instruction,
    required this.voiceInstruction,
    required this.latitude,
    required this.longitude,
    this.targetStopId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'icon': icon,
      'streetName': streetName,
      'instruction': instruction,
      'voiceInstruction': voiceInstruction,
      'latitude': latitude,
      'longitude': longitude,
      'targetStopId': targetStopId,
    };
  }

  factory TurnManeuverModel.fromMap(Map<String, dynamic> map, String id) {
    return TurnManeuverModel(
      id: id,
      type: map['type'] ?? 'continue',
      icon: map['icon'] ?? 'arrow-up',
      streetName: map['streetName'] ?? 'Main Road',
      instruction: map['instruction'] ?? 'Continue straight',
      voiceInstruction: map['voiceInstruction'] ?? 'Continue straight',
      latitude: (map['lat'] as num?)?.toDouble() ?? (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['lng'] as num?)?.toDouble() ?? (map['longitude'] as num?)?.toDouble() ?? 0.0,
      targetStopId: map['targetStopId'],
    );
  }
}

class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint(this.latitude, this.longitude);

  Map<String, double> toMap() => {'lat': latitude, 'lng': longitude};
}

class RouteModel {
  final String id;
  final String routeCode;
  final String routeName;
  final String startLocation;
  final String endLocation;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final List<StopModel> stops;
  final List<LatLngPoint> polylineWaypoints;
  final List<TurnManeuverModel> maneuvers;

  const RouteModel({
    required this.id,
    required this.routeCode,
    required this.routeName,
    required this.startLocation,
    required this.endLocation,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.stops,
    this.polylineWaypoints = const [],
    this.maneuvers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeCode': routeCode,
      'routeName': routeName,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'totalDistanceKm': totalDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'stops': stops.map((s) => s.toMap()).toList(),
      'polylineWaypoints': polylineWaypoints.map((p) => p.toMap()).toList(),
      'maneuvers': maneuvers.map((m) => m.toMap()).toList(),
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    final rawStops = map['stops'] as List<dynamic>? ?? [];
    final parsedStops = rawStops.map((s) => StopModel.fromMap(Map<String, dynamic>.from(s), s['id'] ?? '')).toList();

    final rawWaypoints = map['polylineWaypoints'] as List<dynamic>? ?? [];
    final parsedWaypoints = rawWaypoints.map((w) => LatLngPoint(
      (w['lat'] as num?)?.toDouble() ?? 0.0,
      (w['lng'] as num?)?.toDouble() ?? 0.0,
    )).toList();

    final rawManeuvers = map['maneuvers'] as List<dynamic>? ?? [];
    final parsedManeuvers = rawManeuvers.map((m) => TurnManeuverModel.fromMap(Map<String, dynamic>.from(m), m['id'] ?? '')).toList();

    return RouteModel(
      id: id,
      routeCode: map['routeCode'] ?? 'R-01',
      routeName: map['routeName'] ?? 'Route',
      startLocation: map['startLocation'] ?? 'Depot',
      endLocation: map['endLocation'] ?? 'Campus',
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 0,
      stops: parsedStops,
      polylineWaypoints: parsedWaypoints,
      maneuvers: parsedManeuvers,
    );
  }
}

