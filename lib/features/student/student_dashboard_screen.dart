import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/announcement_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/algorithms/haversine.dart';
import '../../core/algorithms/eta_engine.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';
import 'student_live_map_screen.dart';
import '../auth/welcome_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final UserModel student;

  const StudentDashboardScreen({super.key, required this.student});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final simulationService = SimulationService();
  final attendanceService = AttendanceService();
  final announcementService = AnnouncementService();

  late BusModel assignedBus;
  late RouteModel assignedRoute;

  @override
  void initState() {
    super.initState();
    _loadBusAndRoute();
  }

  void _loadBusAndRoute() {
    assignedBus = simulationService.buses.firstWhere(
      (b) => b.id == (widget.student.assignedBusId ?? 'bus_01'),
      orElse: () => simulationService.buses.first,
    );
    assignedRoute = simulationService.routes.firstWhere(
      (r) => r.id == (widget.student.assignedRouteId ?? 'route_01'),
      orElse: () => simulationService.routes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusModel>>(
      stream: simulationService.fleetStream,
      initialData: simulationService.buses,
      builder: (context, snapshot) {
        final currentBuses = snapshot.data ?? simulationService.buses;
        assignedBus = currentBuses.firstWhere(
          (b) => b.id == (widget.student.assignedBusId ?? 'bus_01'),
          orElse: () => assignedBus,
        );

        // Calculate live distance to student's assigned stop
        final studentStop = assignedRoute.stops.firstWhere(
          (s) => s.id == (widget.student.assignedStopId ?? 'stop_01_03'),
          orElse: () => assignedRoute.stops[2],
        );

        final distanceToStopMeters = assignedBus.liveLocation != null
            ? Haversine.distanceMeters(
                assignedBus.liveLocation!.latitude,
                assignedBus.liveLocation!.longitude,
                studentStop.latitude,
                studentStop.longitude,
              )
            : 2400.0;

        // Calculate live predictive ETA using Method B
        final eta = EtaEngine.calculatePredictiveEta(
          remainingDistanceMeters: distanceToStopMeters,
          remainingStopsCount: 1,
          currentSpeedKmh: assignedBus.liveLocation?.speedKmh ?? 32.0,
          recentSpeedSamplesKmh: [30.0, 32.0, 35.0],
          passengersToPickupAtStops: 8,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryNavy,
            elevation: 0,
            title: const Text("Student Transport Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: "Sign Out",
                onPressed: () {
                  AuthService().signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.student.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Roll: ${widget.student.rollNumber} • ${widget.student.department}",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.accentCyan, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Pickup: ${studentStop.name}",
                                    style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showQrBoardingPass(context),
                        icon: const Icon(Icons.qr_code, color: Colors.white, size: 28),
                        tooltip: "Show Boarding QR Pass",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Button to Open Full Interactive Live Map
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentLiveMapScreen(
                            student: widget.student,
                            bus: assignedBus,
                            route: assignedRoute,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 20),
                    label: const Text(
                      "OPEN FULL LIVE TRACKING MAP",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Assigned Bus Live Status & ETA Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedBus.busNumber,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                "Route: ${assignedRoute.routeName}",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          StatusBadge(status: assignedBus.status),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEtaMetricItem(
                            label: "Estimated Arrival",
                            value: eta.formattedEta,
                            icon: Icons.timer,
                            color: AppColors.primaryBlue,
                          ),
                          _buildEtaMetricItem(
                            label: "Distance to Stop",
                            value: "${(distanceToStopMeters / 1000).toStringAsFixed(1)} km",
                            icon: Icons.alt_route,
                            color: AppColors.skyBlue,
                          ),
                          _buildEtaMetricItem(
                            label: "Confidence",
                            value: "${(eta.confidenceScore * 100).toInt()}%",
                            icon: Icons.verified,
                            color: AppColors.statusMoving,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive Live Street Map
                const Text(
                  "Live Bus Tracking",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: LiveMapWidget(
                    selectedBus: assignedBus,
                    selectedRoute: assignedRoute,
                    showAllFleet: false,
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons: Boarding QR Pass & Missed-Bus Assistance
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showQrBoardingPass(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("My Boarding Pass"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryNavy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showMissedBusDialog(context),
                        icon: const Icon(Icons.help_outline, color: AppColors.primaryNavy),
                        label: const Text("Missed Bus?", style: TextStyle(color: AppColors.primaryNavy)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Transport Announcements
                const Text(
                  "Recent Announcements",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...announcementService.announcements.take(2).map((ann) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        ann.isUrgent ? Icons.warning_amber_rounded : Icons.campaign,
                        color: ann.isUrgent ? Colors.orange : AppColors.primaryBlue,
                      ),
                      title: Text(ann.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(ann.content, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEtaMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showQrBoardingPass(BuildContext context) {
    final token = attendanceService.generateSignedQrToken(
      studentId: widget.student.uid,
      tripId: "trip_01",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Student Boarding Pass", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Present this cryptographically verified QR code to the driver upon boarding.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "${widget.student.displayName} (${widget.student.rollNumber})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              "Valid for 15 minutes • Anti-replay protected",
              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showMissedBusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Missed-Bus Assistance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Did you miss Bus 12? The central control room will evaluate nearby alternative buses heading along your corridor.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Compatible Alternative: Bus 07 (Rajahmundry Direct) has 18 spare seats and will pass your corridor in ~14 mins.",
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Assistance request sent to Control Room Coordinator!"),
                  backgroundColor: AppColors.primaryNavy,
                ),
              );
            },
            child: const Text("Request Transfer"),
          ),
        ],
      ),
    );
  }
}

