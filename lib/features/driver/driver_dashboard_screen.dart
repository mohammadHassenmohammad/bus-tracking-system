import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/models/incident_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/emergency_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';
import 'driver_navigation_screen.dart';
import '../auth/welcome_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final UserModel driver;

  const DriverDashboardScreen({super.key, required this.driver});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final simulationService = SimulationService();
  final attendanceService = AttendanceService();
  final emergencyService = EmergencyService();

  bool _isTripActive = true;
  bool _isTripPaused = false;
  int _currentStopIndex = 2; // Madhavapatnam Bypass
  int _boardedStudentsCount = 38;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusModel>>(
      stream: simulationService.fleetStream,
      initialData: simulationService.buses,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? simulationService.buses;
        final assignedBus = buses.firstWhere(
          (b) => b.id == (widget.driver.assignedBusId ?? 'bus_01'),
          orElse: () => buses.first,
        );
        final assignedRoute = simulationService.routes.firstWhere(
          (r) => r.id == (widget.driver.assignedRouteId ?? 'route_01'),
          orElse: () => simulationService.routes.first,
        );

        final upcomingStop = assignedRoute.stops.length > _currentStopIndex
            ? assignedRoute.stops[_currentStopIndex]
            : assignedRoute.stops.last;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryNavy,
            elevation: 0,
            title: const Text("Driver Operations Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                // Driver Status & Bus Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.driver.displayName} (Driver)",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${assignedBus.busNumber} • ${assignedBus.registrationPlate}",
                            style: const TextStyle(color: AppColors.accentCyan, fontSize: 13),
                          ),
                        ],
                      ),
                      StatusBadge(status: assignedBus.status),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Button to Open Full Live Turn-by-Turn HUD
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverNavigationScreen(
                            driver: widget.driver,
                            bus: assignedBus,
                            route: assignedRoute,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 20),
                    label: const Text(
                      "OPEN LIVE TURN-BY-TURN HUD",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Trip Controls (Start / Pause / End Trip)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTripActive
                              ? (_isTripPaused ? Colors.amber[700] : Colors.green[700])
                              : AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          setState(() {
                            if (!_isTripActive) {
                              _isTripActive = true;
                              _isTripPaused = false;
                              simulationService.startSimulation();
                            } else {
                              _isTripPaused = !_isTripPaused;
                            }
                          });
                        },
                        icon: Icon(_isTripActive ? (_isTripPaused ? Icons.play_arrow : Icons.pause) : Icons.navigation),
                        label: Text(_isTripActive ? (_isTripPaused ? "Resume Trip" : "Pause Trip") : "Start Trip"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _isTripActive = false;
                          _isTripPaused = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Trip completed. GPS tracking ended securely.")),
                        );
                      },
                      child: const Text("End Trip"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Live Navigation & Upcoming Stop Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pin_drop, color: AppColors.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("NEXT UPCOMING STOP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            Text(
                              upcomingStop.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Scheduled: ${upcomingStop.scheduledPickupTime} • ${upcomingStop.registeredStudentCount} Students",
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: AppColors.primaryNavy,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_currentStopIndex < assignedRoute.stops.length - 1) {
                              _currentStopIndex++;
                            }
                          });
                        },
                        child: const Text("Next Stop", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Occupancy & Capacity Monitor
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Passenger Occupancy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("$_boardedStudentsCount / ${assignedBus.totalCapacity} Seats", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _boardedStudentsCount / assignedBus.totalCapacity,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (_boardedStudentsCount / assignedBus.totalCapacity) > 0.9 ? Colors.red : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Interactive Route Map
                SizedBox(
                  height: 260,
                  child: LiveMapWidget(
                    selectedBus: assignedBus,
                    selectedRoute: assignedRoute,
                    showAllFleet: false,
                  ),
                ),

                const SizedBox(height: 16),

                // QR Scanner & Safety Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _simulateScanStudentQr(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan Boarding QR"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onPressed: () => _showBreakdownReportDialog(context, assignedBus),
                      icon: const Icon(Icons.build),
                      label: const Text("Breakdown"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Emergency SOS Button (Accidental Trigger Protected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showEmergencySosDialog(context, assignedBus),
                    icon: const Icon(Icons.emergency, color: Colors.white, size: 24),
                    label: const Text(
                      "EMERGENCY SOS",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _simulateScanStudentQr(BuildContext context) {
    // Generate valid test token for student Aditya Varma
    final token = attendanceService.generateSignedQrToken(
      studentId: "student_001",
      tripId: "trip_01",
    );

    final result = attendanceService.verifyScannedToken(
      base64Token: token,
      currentTripId: "trip_01",
      verifierDriverId: widget.driver.uid,
      studentName: "Aditya Varma",
      rollNumber: "21A91A0501",
      stopId: "stop_01_03",
      stopName: "Madhavapatnam Bypass",
      busLat: 17.0180,
      busLng: 82.1850,
      stopLat: 17.0180,
      stopLng: 82.1850,
    );

    setState(() {
      if (result.isSuccess) {
        _boardedStudentsCount++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? Colors.green[800] : Colors.red[800],
      ),
    );
  }

  void _showBreakdownReportDialog(BuildContext context, BusModel bus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Vehicle Breakdown"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bus: ${bus.busNumber} (${bus.registrationPlate})"),
            Text("Stranded Students: $_boardedStudentsCount"),
            const SizedBox(height: 12),
            const Text("Describe breakdown issue:"),
            const TextField(
              decoration: InputDecoration(
                hintText: "e.g. Engine belt failure, radiator leak",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
            onPressed: () {
              Navigator.pop(ctx);
              simulationService.injectBreakdown(bus.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Breakdown reported to Control Room! Candidate buses evaluated.")),
              );
            },
            child: const Text("Submit & Request Rescue"),
          ),
        ],
      ),
    );
  }

  void _showEmergencySosDialog(BuildContext context, BusModel bus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Confirm Emergency SOS"),
          ],
        ),
        content: const Text(
          "Are you sure you want to broadcast an immediate EMERGENCY SOS? The Central Control Room and authorities will be notified with your live GPS coordinates.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            onPressed: () {
              Navigator.pop(ctx);
              emergencyService.triggerSos(
                busId: bus.id,
                busNumber: bus.busNumber,
                driverId: widget.driver.uid,
                driverName: widget.driver.displayName,
                tripId: "trip_01",
                category: IncidentCategory.accident,
                severity: IncidentSeverity.critical,
                latitude: bus.liveLocation?.latitude ?? 17.0180,
                longitude: bus.liveLocation?.longitude ?? 82.1850,
                description: "Immediate collision / roadside emergency reported by driver",
                passengerCount: _boardedStudentsCount,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("CRITICAL SOS BROADCAST TO CONTROL ROOM!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("BROADCAST SOS"),
          ),
        ],
      ),
    );
  }
}

