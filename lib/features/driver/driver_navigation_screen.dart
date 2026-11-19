import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';

class DriverNavigationScreen extends StatefulWidget {
  final UserModel driver;
  final BusModel bus;
  final RouteModel route;

  const DriverNavigationScreen({
    super.key,
    required this.driver,
    required this.bus,
    required this.route,
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final _simulationService = SimulationService();
  final _attendanceService = AttendanceService();

  bool _isTripActive = true;
  bool _isTripPaused = false;
  bool _isNightMode = false;
  bool _is3DView = false;
  bool _isVoiceEnabled = true;

  int _currentStopIndex = 1;
  int _boardedCount = 38;

  // Turn maneuver simulation state
  final List<Map<String, dynamic>> _maneuvers = [
    {
      'street': 'Head north on Cinema Road / NH-216',
      'subtext': 'Continue straight for 350 meters',
      'distanceMeters': 350,
      'icon': Icons.arrow_upward_rounded,
    },
    {
      'street': 'Turn left onto Main Hospital Road',
      'subtext': 'Onto Market Junction Corridor',
      'distanceMeters': 250,
      'icon': Icons.turn_left_rounded,
    },
    {
      'street': 'Turn right toward Railway Station Road',
      'subtext': 'Approaching Stop 3',
      'distanceMeters': 600,
      'icon': Icons.turn_right_rounded,
    },
    {
      'street': 'Proceed straight along ADB Road',
      'subtext': 'Heading to Aditya University Campus Gate',
      'distanceMeters': 1400,
      'icon': Icons.straight_rounded,
    },
  ];

  int _maneuverIndex = 1;

  void _advanceToNextStop() {
    if (_currentStopIndex < widget.route.stops.length - 1) {
      setState(() {
        _currentStopIndex++;
        _maneuverIndex = (_maneuverIndex + 1) % _maneuvers.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Advanced stop. Now targeting: ${widget.route.stops[_currentStopIndex].name}"),
          backgroundColor: Colors.blue[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPassengerManifest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Passenger Manifest",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                    ),
                    Text(
                      "${widget.route.routeName} • $_boardedCount Boarded",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _ManifestStudentRow(
                    seatNumber: "1",
                    name: "Aditya Varma",
                    rollNumber: "21A91A0501",
                    stopName: "Railway Station",
                    isBoarded: true,
                    boardedTime: "07:54 AM",
                  ),
                  _ManifestStudentRow(
                    seatNumber: "2",
                    name: "Anil Varma",
                    rollNumber: "21A91A0502",
                    stopName: "Main Bus Stand",
                    isBoarded: true,
                    boardedTime: "07:46 AM",
                  ),
                  _ManifestStudentRow(
                    seatNumber: "3",
                    name: "Sneha Reddy",
                    rollNumber: "21A91A0512",
                    stopName: "Collectorate Junction",
                    isBoarded: false,
                    onManualCheckin: () {
                      setState(() => _boardedCount++);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Manual check-in confirmed for Sneha Reddy."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  _ManifestStudentRow(
                    seatNumber: "4",
                    name: "K. Manoj Kumar",
                    rollNumber: "21A91A0520",
                    stopName: "Madhavapatnam Bypass",
                    isBoarded: false,
                    onManualCheckin: () {
                      setState(() => _boardedCount++);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Manual check-in confirmed for K. Manoj Kumar."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencySosDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("Emergency Assistance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Broadcast an urgent SOS distress alert to Central Transport Control and Campus Security? Your live coordinates and passenger count will be transmitted immediately.",
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("CRITICAL: SOS Distress Alert dispatched to Central Control Room!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text("BROADCAST SOS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curManeuver = _maneuvers[_maneuverIndex];
    final nextStop = widget.route.stops.length > _currentStopIndex
        ? widget.route.stops[_currentStopIndex]
        : widget.route.stops.last;
    final remainingStops = widget.route.stops.length - _currentStopIndex;

    return Scaffold(
      backgroundColor: _isNightMode ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // 1. FULL-SCREEN INTERACTIVE VECTOR MAP
          Positioned.fill(
            child: LiveMapWidget(
              selectedBus: widget.bus,
              selectedRoute: widget.route,
              initialZoom: 15.0,
              showAllFleet: false,
            ),
          ),

          // 2. TOP FLOATING EMERALD NAVIGATION CARD (Google Maps Style)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isNightMode ? const Color(0xFF064E3B) : const Color(0xFF0D652D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(curManeuver['icon'] as IconData, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "In ${curManeuver['distanceMeters']} m",
                          style: const TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          curManeuver['street'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          curManeuver['subtext'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _isVoiceEnabled = !_isVoiceEnabled);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isVoiceEnabled ? "Voice navigation enabled" : "Voice navigation muted"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. FLOATING TOOL CONTROLS (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 14,
            child: Column(
              children: [
                _FloatingMapControl(
                  icon: _isNightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  isActive: _isNightMode,
                  onTap: () => setState(() => _isNightMode = !_isNightMode),
                ),
                const SizedBox(height: 8),
                _FloatingMapControl(
                  icon: Icons.view_in_ar_rounded,
                  isActive: _is3DView,
                  onTap: () => setState(() => _is3DView = !_is3DView),
                ),
                const SizedBox(height: 8),
                _FloatingMapControl(
                  icon: Icons.my_location_rounded,
                  isActive: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Centered on live bus coordinates"), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _FloatingMapControl(
                  icon: Icons.fullscreen_exit_rounded,
                  isActive: false,
                  onTap: () => Navigator.of(context).pop(), // Return to dashboard
                ),
              ],
            ),
          ),

          // 4. SPEEDOMETER & SPEED LIMIT BADGE (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 14,
            child: Column(
              children: [
                // Live Speedometer Puck
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBlue, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("34", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
                        Text("km/h", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Speed Limit Badge
                Container(
                  width: 44,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[700]!, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("LIMIT", style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                        Text("40", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey[900])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. DRAGGABLE BOTTOM NAVIGATION SHEET
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              decoration: BoxDecoration(
                color: _isNightMode ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Next Stop Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NEXT REQUIRED STOP",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isNightMode ? const Color(0xFF93C5FD) : AppColors.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextStop.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _isNightMode ? Colors.white : AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(status: _isTripPaused ? 'paused' : 'active'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats Row
                  Row(
                    children: [
                      _NavStatBox(
                        value: "4 mins",
                        label: "Predictive ETA",
                        isNight: _isNightMode,
                      ),
                      const SizedBox(width: 8),
                      _NavStatBox(
                        value: "1.2 km",
                        label: "Distance",
                        isNight: _isNightMode,
                      ),
                      const SizedBox(width: 8),
                      _NavStatBox(
                        value: "$remainingStops",
                        label: "Remaining Stops",
                        isNight: _isNightMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Actions Grid
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _advanceToNextStop,
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "ARRIVED STOP",
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showPassengerManifest,
                          icon: const Icon(Icons.people_alt_outlined, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "MANIFEST",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.red[700]),
                        onPressed: _showEmergencySosDialog,
                        icon: const Icon(Icons.warning_rounded, color: Colors.white),
                        tooltip: "Emergency SOS",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMapControl extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingMapControl({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: isActive ? Colors.white : AppColors.primaryNavy, size: 22),
        ),
      ),
    );
  }
}

class _NavStatBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isNight;

  const _NavStatBox({required this.value, required this.label, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isNight ? const Color(0xFF60A5FA) : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isNight ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManifestStudentRow extends StatelessWidget {
  final String seatNumber;
  final String name;
  final String rollNumber;
  final String stopName;
  final bool isBoarded;
  final String? boardedTime;
  final VoidCallback? onManualCheckin;

  const _ManifestStudentRow({
    required this.seatNumber,
    required this.name,
    required this.rollNumber,
    required this.stopName,
    required this.isBoarded,
    this.boardedTime,
    this.onManualCheckin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isBoarded ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
            child: Text(seatNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBoarded ? Colors.green[800] : AppColors.primaryNavy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryNavy)),
                Text("$rollNumber • Stop: $stopName", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isBoarded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "BOARDED ${boardedTime ?? ''}",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
              ),
            )
          else if (onManualCheckin != null)
            TextButton.icon(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              onPressed: onManualCheckin,
              icon: const Icon(Icons.check, size: 14),
              label: const Text("Check-in", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

