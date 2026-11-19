enum TripStatus {
  scheduled,
  inProgress,
  paused,
  completed,
  cancelled,
}

extension TripStatusExtension on TripStatus {
  String get nameString {
    switch (this) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.inProgress:
        return 'in_progress';
      case TripStatus.paused:
        return 'paused';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  static TripStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return TripStatus.inProgress;
      case 'paused':
        return TripStatus.paused;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.scheduled;
    }
  }
}

class TripModel {
  final String id;
  final String busId;
  final String busNumber;
  final String driverId;
  final String driverName;
  final String routeId;
  final String routeName;
  final String tripType; // 'morning_pickup' or 'evening_drop'
  final TripStatus status;
  final DateTime scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? completedTime;
  final int currentStopIndex;
  final int boardedCount;
  final int droppedCount;

  const TripModel({
    required this.id,
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.driverName,
    required this.routeId,
    required this.routeName,
    this.tripType = 'morning_pickup',
    this.status = TripStatus.scheduled,
    required this.scheduledStartTime,
    this.actualStartTime,
    this.completedTime,
    this.currentStopIndex = 0,
    this.boardedCount = 0,
    this.droppedCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'busNumber': busNumber,
      'driverId': driverId,
      'driverName': driverName,
      'routeId': routeId,
      'routeName': routeName,
      'tripType': tripType,
      'status': status.nameString,
      'scheduledStartTime': scheduledStartTime.millisecondsSinceEpoch,
      'actualStartTime': actualStartTime?.millisecondsSinceEpoch,
      'completedTime': completedTime?.millisecondsSinceEpoch,
      'currentStopIndex': currentStopIndex,
      'boardedCount': boardedCount,
      'droppedCount': droppedCount,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      busId: map['busId'] ?? '',
      busNumber: map['busNumber'] ?? 'Bus',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Driver',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? 'Route',
      tripType: map['tripType'] ?? 'morning_pickup',
      status: TripStatusExtension.fromString(map['status'] ?? 'scheduled'),
      scheduledStartTime: DateTime.fromMillisecondsSinceEpoch(
        (map['scheduledStartTime'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      actualStartTime: map['actualStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['actualStartTime'] as num).toInt())
          : null,
      completedTime: map['completedTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['completedTime'] as num).toInt())
          : null,
      currentStopIndex: (map['currentStopIndex'] as num?)?.toInt() ?? 0,
      boardedCount: (map['boardedCount'] as num?)?.toInt() ?? 0,
      droppedCount: (map['droppedCount'] as num?)?.toInt() ?? 0,
    );
  }

  TripModel copyWith({
    TripStatus? status,
    int? currentStopIndex,
    int? boardedCount,
    int? droppedCount,
    DateTime? actualStartTime,
    DateTime? completedTime,
  }) {
    return TripModel(
      id: id,
      busId: busId,
      busNumber: busNumber,
      driverId: driverId,
      driverName: driverName,
      routeId: routeId,
      routeName: routeName,
      tripType: tripType,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      completedTime: completedTime ?? this.completedTime,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      boardedCount: boardedCount ?? this.boardedCount,
      droppedCount: droppedCount ?? this.droppedCount,
    );
  }
}

