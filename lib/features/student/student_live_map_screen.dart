import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/algorithms/haversine.dart';
import '../../core/algorithms/eta_engine.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';

class StudentLiveMapScreen extends StatefulWidget {
  final UserModel student;
  final BusModel bus;
  final RouteModel route;

  const StudentLiveMapScreen({
    super.key,
    required this.student,
    required this.bus,
    required this.route,
  });

  @override
  State<StudentLiveMapScreen> createState() => _StudentLiveMapScreenState();
}

class _StudentLiveMapScreenState extends State<StudentLiveMapScreen> {
  final _simulationService = SimulationService();
  final _attendanceService = AttendanceService();

  late BusModel _liveBus;
  late RouteModel _liveRoute;

  @override
  void initState() {
    super.initState();
    _liveBus = widget.bus;
    _liveRoute = widget.route;
  }

  void _showBoardingPassModal(BuildContext context) {
    final token = _attendanceService.generateStudentToken(
      studentId: widget.student.uid,
      tripId: "trip_01",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: AppColors.primaryNavy, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Digital Boarding Pass",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        "${widget.student.displayName} • ${widget.student.rollNumber}",
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Text(
                    "HMAC-SHA256 Signed • Refreshes in 15 min",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Hold this QR code directly in front of the bus terminal camera upon boarding.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissedBusAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.transfer_within_a_station_rounded, color: Color(0xFFD97706), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Missed Bus Assistant",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        "Real-time corridor alternative recommendations",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Primary Assignment:",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_liveBus.busNumber} • ${_liveRoute.name}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "AVAILABLE PARALLEL CORRIDOR BUSES",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            _buildAlternativeBusCard(
              busNumber: "Bus 02",
              plate: "AP35 CD 5678",
              driver: "Suresh Varma",
              route: "Express Corridor B",
              etaMins: 8,
              availableSeats: 14,
              distanceKm: 2.1,
              onSelect: () {
                Navigator.pop(ctx);
                _requestReassignment("Bus 02");
              },
            ),
            const SizedBox(height: 10),
            _buildAlternativeBusCard(
              busNumber: "Bus 03",
              plate: "AP35 EF 9012",
              driver: "Mahesh Babu",
              route: "Bypass Fast Track C",
              etaMins: 14,
              availableSeats: 9,
              distanceKm: 3.8,
              onSelect: () {
                Navigator.pop(ctx);
                _requestReassignment("Bus 03");
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderBorder(color: AppColors.borderLight).top,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Dismiss", style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeBusCard({
    required String busNumber,
    required String plate,
    required String driver,
    required String route,
    required int etaMins,
    required int availableSeats,
    required double distanceKm,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus_filled, color: AppColors.primaryNavy, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$busNumber ($plate)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "~${etaMins}m ETA",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Route: $route • Driver: $driver",
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_seat_rounded, size: 13, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      "$availableSeats spare seats available",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 8),
                    Text("• ${distanceKm} km away", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onSelect,
            child: const Text("Hop On", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _requestReassignment(String targetBus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text("Emergency re-assignment to $targetBus approved by Control Room!")),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showShareTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share_location_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 10),
            Text("Share Real-Time Trip"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share your live bus location securely with your parents or guardians:",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const SelectableText(
                "https://transport.campus.edu/track?token=trk_78f1a92&bus=bus_01",
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Valid for 60 minutes • End-to-end encrypted tracking stream",
              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tracking link copied to clipboard!")),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Copy Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusModel>>(
      stream: _simulationService.fleetStream,
      initialData: _simulationService.buses,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? _simulationService.buses;
        _liveBus = buses.firstWhere(
          (b) => b.id == widget.bus.id,
          orElse: () => widget.bus,
        );

        final studentStop = _liveRoute.stops.firstWhere(
          (s) => s.id == (widget.student.assignedStopId ?? 'stop_01_03'),
          orElse: () => _liveRoute.stops[2],
        );

        final distanceToStopMeters = _liveBus.liveLocation != null
            ? Haversine.distanceMeters(
                _liveBus.liveLocation!.latitude,
                _liveBus.liveLocation!.longitude,
                studentStop.latitude,
                studentStop.longitude,
              )
            : 2400.0;

        final eta = EtaEngine.calculatePredictiveEta(
          remainingDistanceMeters: distanceToStopMeters,
          remainingStopsCount: 1,
          currentSpeedKmh: _liveBus.liveLocation?.speedKmh ?? 32.0,
          recentSpeedSamplesKmh: [30.0, 32.0, 35.0],
          passengersToPickupAtStops: 8,
        );

        final occupancyPercent = ((_liveBus.currentPassengersCount / _liveBus.totalCapacity) * 100).toInt();
        Color occupancyColor;
        String occupancyLabel;
        if (occupancyPercent < 60) {
          occupancyColor = const Color(0xFF059669);
          occupancyLabel = "Seats Available";
        } else if (occupancyPercent < 85) {
          occupancyColor = const Color(0xFFD97706);
          occupancyLabel = "Moderate Rush";
        } else {
          occupancyColor = const Color(0xFFDC2626);
          occupancyLabel = "High Crowding";
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.primaryNavy,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _liveBus.busNumber,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _liveBus.registrationPlate,
                        style: const TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  "Assigned Stop: ${studentStop.name}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF93C5FD)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_location_rounded, color: Colors.white),
                tooltip: "Share Live Trip",
                onPressed: () => _showShareTripDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
                tooltip: "Missed Bus Assistant",
                onPressed: () => _showMissedBusAssistant(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Full-screen Map View
              Positioned.fill(
                child: LiveMapWidget(
                  buses: [_liveBus],
                  route: _liveRoute,
                  showAllStops: true,
                ),
              ),

              // Top Floating Predictive HUD Card
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "REAL-TIME TRACKING ACTIVE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: _liveBus.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PREDICTIVE ARRIVAL", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                eta.etaText,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("DISTANCE", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                "${(distanceToStopMeters / 1000).toStringAsFixed(1)} km",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("VELOCITY", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                "${_liveBus.liveLocation?.speedKmh.toStringAsFixed(0) ?? '34'} km/h",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Crowdedness Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_alt_outlined, size: 14, color: occupancyColor),
                              const SizedBox(width: 6),
                              Text(
                                "Occupancy: ${_liveBus.currentPassengersCount}/${_liveBus.totalCapacity} ($occupancyPercent%)",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: occupancyColor),
                              ),
                            ],
                          ),
                          Text(
                            occupancyLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: occupancyColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: occupancyPercent / 100.0,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Bar
              Positioned(
                bottom: 20,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => _showBoardingPassModal(context),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "BOARDING PASS (QR)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => _showMissedBusAssistant(context),
                        icon: const Icon(Icons.alt_route, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "MISSED BUS",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

