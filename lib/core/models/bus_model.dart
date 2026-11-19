import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum BusOperationalStatus {
  moving,
  stationary,
  delayed,
  offline,
  breakdown,
  emergency,
}

extension BusOperationalStatusExtension on BusOperationalStatus {
  String get nameString {
    switch (this) {
      case BusOperationalStatus.moving:
        return 'moving';
      case BusOperationalStatus.stationary:
        return 'stationary';
      case BusOperationalStatus.delayed:
        return 'delayed';
      case BusOperationalStatus.offline:
        return 'offline';
      case BusOperationalStatus.breakdown:
        return 'breakdown';
      case BusOperationalStatus.emergency:
        return 'emergency';
    }
  }

  Color get color {
    switch (this) {
      case BusOperationalStatus.moving:
        return AppColors.statusMoving;
      case BusOperationalStatus.stationary:
        return AppColors.statusStationary;
      case BusOperationalStatus.delayed:
        return AppColors.statusDelayed;
      case BusOperationalStatus.offline:
        return AppColors.statusOffline;
      case BusOperationalStatus.breakdown:
        return AppColors.statusBreakdown;
      case BusOperationalStatus.emergency:
        return AppColors.statusEmergency;
    }
  }

  String get label {
    switch (this) {
      case BusOperationalStatus.moving:
        return 'Moving (On-Route)';
      case BusOperationalStatus.stationary:
        return 'Stationary (At Stop)';
      case BusOperationalStatus.delayed:
        return 'Delayed';
      case BusOperationalStatus.offline:
        return 'Offline';
      case BusOperationalStatus.breakdown:
        return 'Breakdown';
      case BusOperationalStatus.emergency:
        return 'Emergency SOS';
    }
  }

  static BusOperationalStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'moving':
        return BusOperationalStatus.moving;
      case 'stationary':
        return BusOperationalStatus.stationary;
      case 'delayed':
        return BusOperationalStatus.delayed;
      case 'breakdown':
        return BusOperationalStatus.breakdown;
      case 'emergency':
        return BusOperationalStatus.emergency;
      default:
        return BusOperationalStatus.offline;
    }
  }
}

class BusLiveLocation {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isSimulation;
  final String? busId;
  final String? tripId;
  final String? driverUid;
  final String? deviceSessionId;
  final double speedMetersPerSecond;
  final int sequenceNumber;
  final String trackingStatus;

  const BusLiveLocation({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.heading,
    required this.accuracyMeters,
    required this.timestamp,
    this.isSimulation = false,
    this.busId,
    this.tripId,
    this.driverUid,
    this.deviceSessionId,
    this.speedMetersPerSecond = 0.0,
    this.sequenceNumber = 1,
    this.trackingStatus = 'active',
  });

  bool get isFresh {
    final ageSeconds = DateTime.now().difference(timestamp).inSeconds;
    return ageSeconds < 30; // 30-second freshness window
  }

  String get freshnessLabel {
    final age = DateTime.now().difference(timestamp).inSeconds;
    if (age <= 5) return "Live (Just now)";
    if (age < 60) return "$age s ago";
    final mins = (age / 60).floor();
    return "$mins min${mins > 1 ? 's' : ''} ago (Stale)";
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'tripId': tripId,
      'driverUid': driverUid,
      'deviceSessionId': deviceSessionId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speedKmh,
      'speedMetersPerSecond': speedMetersPerSecond,
      'heading': heading,
      'accuracy': accuracyMeters,
      'sequenceNumber': sequenceNumber,
      'trackingStatus': trackingStatus,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSimulation': isSimulation,
    };
  }

  factory BusLiveLocation.fromMap(Map<dynamic, dynamic> map) {
    final speed = (map['speed'] as num?)?.toDouble() ?? 
                  ((map['speedKmh'] as num?)?.toDouble() ?? 0.0);
    final speedMps = (map['speedMetersPerSecond'] as num?)?.toDouble() ?? (speed / 3.6);
    return BusLiveLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      speedKmh: speed,
      speedMetersPerSecond: speedMps,
      heading: (map['heading'] as num?)?.toDouble() ?? ((map['headingDegrees'] as num?)?.toDouble() ?? 0.0),
      accuracyMeters: (map['accuracy'] as num?)?.toDouble() ?? ((map['accuracyMeters'] as num?)?.toDouble() ?? 10.0),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['deviceTimestamp'] as num?)?.toInt() ?? 
        ((map['serverReceivedAt'] as num?)?.toInt() ?? 
        ((map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch)),
      ),
      isSimulation: map['isSimulation'] as bool? ?? false,
      busId: map['busId'] as String?,
      tripId: map['tripId'] as String?,
      driverUid: map['driverUid'] as String?,
      deviceSessionId: map['deviceSessionId'] as String?,
      sequenceNumber: (map['sequenceNumber'] as num?)?.toInt() ?? ((map['sequence'] as num?)?.toInt() ?? 1),
      trackingStatus: map['trackingStatus'] as String? ?? 'active',
    );
  }
}

class BusModel {
  final String id;
  final String busNumber;
  final String registrationPlate;
  final int totalCapacity;
  final int occupiedSeats;
  final BusOperationalStatus status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedRouteId;
  final String? assignedRouteName;
  final BusLiveLocation? liveLocation;
  final double fuelLevelPercentage;
  final double odometerKm;

  const BusModel({
    required this.id,
    required this.busNumber,
    required this.registrationPlate,
    this.totalCapacity = 50,
    this.occupiedSeats = 0,
    this.status = BusOperationalStatus.offline,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedRouteId,
    this.assignedRouteName,
    this.liveLocation,
    this.fuelLevelPercentage = 85.0,
    this.odometerKm = 24500.0,
  });

  int get spareCapacity => (totalCapacity - occupiedSeats).clamp(0, totalCapacity);
  double get occupancyRate => totalCapacity > 0 ? (occupiedSeats / totalCapacity) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busNumber': busNumber,
      'registrationPlate': registrationPlate,
      'totalCapacity': totalCapacity,
      'occupiedSeats': occupiedSeats,
      'status': status.nameString,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'fuelLevelPercentage': fuelLevelPercentage,
      'odometerKm': odometerKm,
    };
  }

  factory BusModel.fromMap(Map<String, dynamic> map, String id) {
    return BusModel(
      id: id,
      busNumber: map['busNumber'] ?? 'Bus',
      registrationPlate: map['registrationPlate'] ?? 'AP-05-XXXX',
      totalCapacity: (map['totalCapacity'] as num?)?.toInt() ?? 50,
      occupiedSeats: (map['occupiedSeats'] as num?)?.toInt() ?? 0,
      status: BusOperationalStatusExtension.fromString(map['status'] ?? 'offline'),
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      assignedRouteId: map['assignedRouteId'],
      assignedRouteName: map['assignedRouteName'],
      fuelLevelPercentage: (map['fuelLevelPercentage'] as num?)?.toDouble() ?? 80.0,
      odometerKm: (map['odometerKm'] as num?)?.toDouble() ?? 20000.0,
    );
  }

  BusModel copyWith({
    BusOperationalStatus? status,
    int? occupiedSeats,
    BusLiveLocation? liveLocation,
    String? assignedDriverId,
    String? assignedDriverName,
    String? assignedRouteId,
    String? assignedRouteName,
  }) {
    return BusModel(
      id: id,
      busNumber: busNumber,
      registrationPlate: registrationPlate,
      totalCapacity: totalCapacity,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedRouteId: assignedRouteId ?? this.assignedRouteId,
      assignedRouteName: assignedRouteName ?? this.assignedRouteName,
      liveLocation: liveLocation ?? this.liveLocation,
      fuelLevelPercentage: fuelLevelPercentage,
      odometerKm: odometerKm,
    );
  }
}

