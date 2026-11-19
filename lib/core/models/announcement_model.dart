class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'holiday', 'delay', 'route_change', 'exam', 'emergency', 'general'
  final String targetRole; // 'all', 'student', 'guardian', 'driver'
  final String? targetRouteId;
  final String? targetBusId;
  final bool isUrgent;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.targetRole = 'all',
    this.targetRouteId,
    this.targetBusId,
    this.isUrgent = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'targetRole': targetRole,
      'targetRouteId': targetRouteId,
      'targetBusId': targetBusId,
      'isUrgent': isUrgent,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? 'Notice',
      content: map['content'] ?? '',
      category: map['category'] ?? 'general',
      targetRole: map['targetRole'] ?? 'all',
      targetRouteId: map['targetRouteId'],
      targetBusId: map['targetBusId'],
      isUrgent: map['isUrgent'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class BreakdownAssistanceRequest {
  final String id;
  final String incidentId;
  final String brokenBusId;
  final String brokenBusNumber;
  final String? assignedReplacementBusId;
  final String? assignedReplacementBusNumber;
  final String? receivingDriverId;
  final int passengerCount;
  final String status; // 'requested', 'approved', 'accepted', 'completed'
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;

  const BreakdownAssistanceRequest({
    required this.id,
    required this.incidentId,
    required this.brokenBusId,
    required this.brokenBusNumber,
    this.assignedReplacementBusId,
    this.assignedReplacementBusNumber,
    this.receivingDriverId,
    required this.passengerCount,
    this.status = 'requested',
    required this.requestedAt,
    this.approvedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incidentId': incidentId,
      'brokenBusId': brokenBusId,
      'brokenBusNumber': brokenBusNumber,
      'assignedReplacementBusId': assignedReplacementBusId,
      'assignedReplacementBusNumber': assignedReplacementBusNumber,
      'receivingDriverId': receivingDriverId,
      'passengerCount': passengerCount,
      'status': status,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory BreakdownAssistanceRequest.fromMap(Map<String, dynamic> map, String id) {
    return BreakdownAssistanceRequest(
      id: id,
      incidentId: map['incidentId'] ?? '',
      brokenBusId: map['brokenBusId'] ?? '',
      brokenBusNumber: map['brokenBusNumber'] ?? 'Bus',
      assignedReplacementBusId: map['assignedReplacementBusId'],
      assignedReplacementBusNumber: map['assignedReplacementBusNumber'],
      receivingDriverId: map['receivingDriverId'],
      passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'requested',
      requestedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['requestedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      approvedAt: map['approvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['approvedAt'] as num).toInt())
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['completedAt'] as num).toInt())
          : null,
    );
  }
}

