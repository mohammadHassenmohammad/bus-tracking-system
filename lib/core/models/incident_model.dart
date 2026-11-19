enum IncidentCategory {
  breakdown,
  accident,
  medical,
  fire,
  security,
  other,
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum IncidentStatus {
  reported,
  acknowledged,
  assigned,
  resolved,
}

extension IncidentCategoryExtension on IncidentCategory {
  String get nameString => toString().split('.').last;
  String get label {
    switch (this) {
      case IncidentCategory.breakdown:
        return 'Vehicle Breakdown';
      case IncidentCategory.accident:
        return 'Traffic Accident';
      case IncidentCategory.medical:
        return 'Medical Emergency';
      case IncidentCategory.fire:
        return 'Fire / Smoke Hazard';
      case IncidentCategory.security:
        return 'Security Concern';
      case IncidentCategory.other:
        return 'General Emergency';
    }
  }

  static IncidentCategory fromString(String val) {
    return IncidentCategory.values.firstWhere(
      (e) => e.nameString == val.toLowerCase(),
      orElse: () => IncidentCategory.other,
    );
  }
}

class IncidentModel {
  final String id;
  final String busId;
  final String busNumber;
  final String driverId;
  final String driverName;
  final String tripId;
  final IncidentCategory category;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final double latitude;
  final double longitude;
  final String description;
  final int passengerCount;
  final DateTime reportedAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolutionSummary;

  const IncidentModel({
    required this.id,
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.driverName,
    required this.tripId,
    required this.category,
    this.severity = IncidentSeverity.high,
    this.status = IncidentStatus.reported,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.passengerCount = 0,
    required this.reportedAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolutionSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'busNumber': busNumber,
      'driverId': driverId,
      'driverName': driverName,
      'tripId': tripId,
      'category': category.nameString,
      'severity': severity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'passengerCount': passengerCount,
      'reportedAt': reportedAt.millisecondsSinceEpoch,
      'acknowledgedAt': acknowledgedAt?.millisecondsSinceEpoch,
      'acknowledgedBy': acknowledgedBy,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'resolutionSummary': resolutionSummary,
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map, String id) {
    return IncidentModel(
      id: id,
      busId: map['busId'] ?? '',
      busNumber: map['busNumber'] ?? 'Bus',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Driver',
      tripId: map['tripId'] ?? '',
      category: IncidentCategoryExtension.fromString(map['category'] ?? 'other'),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == (map['severity'] ?? 'high'),
        orElse: () => IncidentSeverity.high,
      ),
      status: IncidentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'reported'),
        orElse: () => IncidentStatus.reported,
      ),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 0,
      reportedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['reportedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      acknowledgedAt: map['acknowledgedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['acknowledgedAt'] as num).toInt())
          : null,
      acknowledgedBy: map['acknowledgedBy'],
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['resolvedAt'] as num).toInt())
          : null,
      resolutionSummary: map['resolutionSummary'],
    );
  }

  IncidentModel copyWith({
    IncidentStatus? status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolutionSummary,
  }) {
    return IncidentModel(
      id: id,
      busId: busId,
      busNumber: busNumber,
      driverId: driverId,
      driverName: driverName,
      tripId: tripId,
      category: category,
      severity: severity,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      description: description,
      passengerCount: passengerCount,
      reportedAt: reportedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
    );
  }
}

