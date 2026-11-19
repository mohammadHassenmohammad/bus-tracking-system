import 'dart:async';
import '../models/announcement_model.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal() {
    _initializeAnnouncements();
  }

  final List<AnnouncementModel> _announcements = [];
  final List<String> _inAppNotificationLogs = [];

  final _announcementsController = StreamController<List<AnnouncementModel>>.broadcast();
  Stream<List<AnnouncementModel>> get announcementsStream => _announcementsController.stream;

  List<AnnouncementModel> get announcements => List.unmodifiable(_announcements);
  List<String> get notificationLogs => List.unmodifiable(_inAppNotificationLogs);

  void _initializeAnnouncements() {
    _announcements.addAll([
      AnnouncementModel(
        id: 'ann_01',
        title: 'Mid-Term Examinations: Special Bus Timings',
        content: 'Morning bus departure from all terminal points will commence 20 minutes earlier (06:55 AM) from Nov 20 to Nov 25 to accommodate the 09:00 AM exam schedule.',
        category: 'exam',
        targetRole: 'all',
        isUrgent: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AnnouncementModel(
        id: 'ann_02',
        title: 'Route 01 Detour Notification',
        content: 'Due to road maintenance on the Samalkot canal bridge, Bus 12 will use the bypass road. Madhavapatnam stop students will board at the flyover intersection.',
        category: 'route_change',
        targetRole: 'student',
        targetRouteId: 'route_01',
        targetBusId: 'bus_01',
        isUrgent: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
      AnnouncementModel(
        id: 'ann_03',
        title: 'Upcoming Public Holiday: Transport Suspended',
        content: 'Campus transport services will remain suspended on the upcoming festival holiday. Operations will resume normal schedules the following working day.',
        category: 'holiday',
        targetRole: 'all',
        isUrgent: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    _inAppNotificationLogs.addAll([
      "Your assigned Bus 12 is approaching: ~1.4 km from your pickup stop.",
      "Bus 12 has arrived at Madhavapatnam Bypass Stop.",
      "Attendance verified: Student Aditya Varma boarded Bus 12 at 07:39 AM.",
    ]);
  }

  void addAnnouncement(AnnouncementModel ann) {
    _announcements.insert(0, ann);
    _announcementsController.add(_announcements);
  }

  void logProximityAlert(String message) {
    _inAppNotificationLogs.insert(0, message);
  }

  List<AnnouncementModel> getForRole(String role, {String? routeId, String? busId}) {
    return _announcements.where((a) {
      if (a.targetRole != 'all' && a.targetRole != role) return false;
      if (a.targetRouteId != null && routeId != null && a.targetRouteId != routeId) return false;
      if (a.targetBusId != null && busId != null && a.targetBusId != busId) return false;
      return true;
    }).toList();
  }
}

