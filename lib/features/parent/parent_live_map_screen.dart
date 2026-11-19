import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/algorithms/haversine.dart';
import '../../core/algorithms/eta_engine.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';

class ParentLiveMapScreen extends StatefulWidget {
  final UserModel guardian;
  final BusModel bus;
  final RouteModel route;

  const ParentLiveMapScreen({
    super.key,
    required this.guardian,
    required this.bus,
    required this.route,
  });

  @override
  State<ParentLiveMapScreen> createState() => _ParentLiveMapScreenState();
}

class _ParentLiveMapScreenState extends State<ParentLiveMapScreen> {
  final _simulationService = SimulationService();

  late BusModel _liveBus;
  late RouteModel _liveRoute;

  // Multi-child switcher
  String _selectedChild = "Aditya Varma (21A91A0501)";
  final List<String> _children = [
    "Aditya Varma (21A91A0501)",
    "Sneha Varma (23A91A0412)",
  ];

  // Geofence radius slider (500m - 2500m)
  double _geofenceRadiusMeters = 1000.0;
  bool _isGeofenceAlertActive = true;

  @override
  void initState() {
    super.initState();
    _liveBus = widget.bus;
    _liveRoute = widget.route;
  }

  void _showTimelineModal(BuildContext context) {
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Verified Journey Timeline",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      _selectedChild,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTimelineStep(
              time: "07:42 AM",
              title: "Boarded Bus 01 at Madhavapatnam Stop",
              description: "Scanned via Cryptographic QR Token. Confirmed on manifest.",
              isCompleted: true,
              isFirst: true,
            ),
            _buildTimelineStep(
              time: "08:05 AM",
              title: "Passed Collectorate Junction",
              description: "Current speed 36 km/h. On designated NH-216 corridor.",
              isCompleted: true,
            ),
            _buildTimelineStep(
              time: "08:18 AM",
              title: "Geofence Radius Triggered",
              description: "Bus is now within 1.0 km of student's destination stop.",
              isCompleted: true,
            ),
            _buildTimelineStep(
              time: "08:35 AM",
              title: "Estimated Arrival at College Main Gate",
              description: "Safe campus drop-off with automatic parent push notification.",
              isCompleted: false,
              isLast: true,
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
                child: const Text("Close Timeline", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String time,
    required String title,
    required String description,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF059669) : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  if (isCompleted)
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 6,
                    ),
                ],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? const Color(0xFF059669) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF059669) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  void _showSpeedDial(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
            const Text(
              "Direct Emergency Contacts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "One-tap speed dial to transport supervisors and emergency desks",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _buildSpeedDialOption(
              icon: Icons.person_pin_rounded,
              name: "Call Driver (Ravi Kumar)",
              phone: "+91 98480 12345",
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.pop(ctx);
                _callNumber("+91 98480 12345");
              },
            ),
            const SizedBox(height: 10),
            _buildSpeedDialOption(
              icon: Icons.support_agent_rounded,
              name: "Central Transport Control Room",
              phone: "+91 884 2300999",
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.pop(ctx);
                _callNumber("+91 884 2300999");
              },
            ),
            const SizedBox(height: 10),
            _buildSpeedDialOption(
              icon: Icons.security_rounded,
              name: "Campus Security & SOS Helpline",
              phone: "112 / +91 884 2300112",
              color: const Color(0xFFDC2626),
              onTap: () {
                Navigator.pop(ctx);
                _callNumber("112");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String name,
    required String phone,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  Text(phone, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.phone_in_talk_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _callNumber(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Simulating outgoing call to $number..."),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
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

        final studentStop = _liveRoute.stops[2]; // Madhavapatnam stop

        final distanceToStopMeters = _liveBus.liveLocation != null
            ? Haversine.distanceMeters(
                _liveBus.liveLocation!.latitude,
                _liveBus.liveLocation!.longitude,
                studentStop.latitude,
                studentStop.longitude,
              )
            : 1800.0;

        final isInsideGeofence = distanceToStopMeters <= _geofenceRadiusMeters;

        final eta = EtaEngine.calculatePredictiveEta(
          remainingDistanceMeters: distanceToStopMeters,
          remainingStopsCount: 1,
          currentSpeedKmh: _liveBus.liveLocation?.speedKmh ?? 32.0,
          recentSpeedSamplesKmh: [30.0, 32.0, 35.0],
          passengersToPickupAtStops: 4,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChild,
                dropdownColor: const Color(0xFF1E3A8A),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                items: _children.map((child) {
                  return DropdownMenuItem<String>(
                    value: child,
                    child: Text(child),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedChild = val);
                  }
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                tooltip: "Journey Timeline",
                onPressed: () => _showTimelineModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
                tooltip: "Emergency Speed-Dial",
                onPressed: () => _showSpeedDial(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Live Map
              Positioned.fill(
                child: LiveMapWidget(
                  buses: [_liveBus],
                  route: _liveRoute,
                  showAllStops: true,
                ),
              ),

              // Top Floating Safety Card
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
                                decoration: BoxDecoration(
                                  color: isInsideGeofence ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isInsideGeofence ? "INSIDE SAFE GEOFENCE RADIUS" : "BUS EN-ROUTE TO CORRIDOR",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isInsideGeofence ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: _liveBus.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ESTIMATED ARRIVAL", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                eta.etaText,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("REMAINING DISTANCE", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                "${(distanceToStopMeters / 1000).toStringAsFixed(1)} km",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("DRIVER", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const Text(
                                "Ravi Kumar",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Geofence Radius Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF1E3A8A)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Geofence Alert Radius: ${(_geofenceRadiusMeters / 1000).toStringAsFixed(1)} km",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                              Text(
                                isInsideGeofence ? "ALERTER TRIGGERED" : "Active Monitor",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isInsideGeofence ? const Color(0xFF059669) : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF1E3A8A),
                              inactiveTrackColor: Colors.grey[200],
                              thumbColor: const Color(0xFF1E3A8A),
                              overlayColor: const Color(0xFF1E3A8A).withOpacity(0.12),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _geofenceRadiusMeters,
                              min: 500,
                              max: 2500,
                              divisions: 8,
                              label: "${(_geofenceRadiusMeters / 1000).toStringAsFixed(1)} km",
                              onChanged: (val) {
                                setState(() => _geofenceRadiusMeters = val);
                              },
                            ),
                          ),
                        ],
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
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => _showTimelineModal(context),
                        icon: const Icon(Icons.history_edu_rounded, size: 20),
                        label: const Text(
                          "JOURNEY TIMELINE",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: () => _showSpeedDial(context),
                        icon: const Icon(Icons.phone_in_talk, size: 18),
                        label: const Text(
                          "SPEED-DIAL",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

