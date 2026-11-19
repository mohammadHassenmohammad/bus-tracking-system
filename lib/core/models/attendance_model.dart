enum AttendanceStatus {
  boarded,
  dropped,
  absent,
  missed,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get nameString {
    switch (this) {
      case AttendanceStatus.boarded:
        return 'boarded';
      case AttendanceStatus.dropped:
        return 'dropped';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.missed:
        return 'missed';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.boarded:
        return 'Boarded Bus';
      case AttendanceStatus.dropped:
        return 'Safely Dropped';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.missed:
        return 'Missed Bus';
    }
  }

  static AttendanceStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'boarded':
        return AttendanceStatus.boarded;
      case 'dropped':
        return AttendanceStatus.dropped;
      case 'missed':
        return AttendanceStatus.missed;
      default:
        return AttendanceStatus.absent;
    }
  }
}

class AttendanceModel {
  final String id;
  final String tripId;
  final String busId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String stopId;
  final String stopName;
  final AttendanceStatus status;
  final DateTime timestamp;
  final String verifiedByDriverId;
  final String verificationMethod; // 'qr_code', 'driver_manual', 'rfid_adapter'
  final bool isGeofenceVerified;
  final bool isManualCorrection;
  final String? correctionReason;

  const AttendanceModel({
    required this.id,
    required this.tripId,
    required this.busId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.stopId,
    required this.stopName,
    required this.status,
    required this.timestamp,
    required this.verifiedByDriverId,
    this.verificationMethod = 'qr_code',
    this.isGeofenceVerified = true,
    this.isManualCorrection = false,
    this.correctionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'busId': busId,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'stopId': stopId,
      'stopName': stopName,
      'status': status.nameString,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'verifiedByDriverId': verifiedByDriverId,
      'verificationMethod': verificationMethod,
      'isGeofenceVerified': isGeofenceVerified,
      'isManualCorrection': isManualCorrection,
      'correctionReason': correctionReason,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      tripId: map['tripId'] ?? '',
      busId: map['busId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Student',
      rollNumber: map['rollNumber'] ?? '',
      stopId: map['stopId'] ?? '',
      stopName: map['stopName'] ?? 'Stop',
      status: AttendanceStatusExtension.fromString(map['status'] ?? 'boarded'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      verifiedByDriverId: map['verifiedByDriverId'] ?? '',
      verificationMethod: map['verificationMethod'] ?? 'qr_code',
      isGeofenceVerified: map['isGeofenceVerified'] as bool? ?? false,
      isManualCorrection: map['isManualCorrection'] as bool? ?? false,
      correctionReason: map['correctionReason'],
    );
  }
}

