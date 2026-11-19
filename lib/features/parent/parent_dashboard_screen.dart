import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/status_badge.dart';
import 'parent_live_map_screen.dart';
import '../auth/welcome_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final UserModel guardian;

  const ParentDashboardScreen({super.key, required this.guardian});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final simulationService = SimulationService();
  final attendanceService = AttendanceService();
  String _selectedChild = "Aditya Varma (21A91A0501)";
  final List<String> _children = [
    "Aditya Varma (21A91A0501)",
    "Sneha Varma (23A91A0412)",
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusModel>>(
      stream: simulationService.fleetStream,
      initialData: simulationService.buses,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? simulationService.buses;
        final targetBusId = widget.guardian.assignedBusId ?? (buses.isNotEmpty ? buses.first.id : 'bus_01');
        final assignedBus = buses.firstWhere(
          (b) => b.id == targetBusId,
          orElse: () => buses.first,
        );
        final assignedRoute = simulationService.routes.firstWhere(
          (r) => r.id == (assignedBus.assignedRouteId ?? (simulationService.routes.isNotEmpty ? simulationService.routes.first.id : 'route_01')),
          orElse: () => simulationService.routes.first,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            title: const Text("Parent Safety Portal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                // Guardian Header Card with Child Selector
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF3B82F6),
                            child: Icon(Icons.family_restroom, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome, ${widget.guardian.displayName}",
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Parent / Guardian Account",
                                  style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.school_rounded, color: Color(0xFF93C5FD), size: 16),
                                SizedBox(width: 6),
                                Text("Child:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedChild,
                                  isExpanded: true,
                                  alignment: Alignment.centerRight,
                                  dropdownColor: const Color(0xFF1E3A8A),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  items: _children.map((child) {
                                    return DropdownMenuItem<String>(
                                      value: child,
                                      child: Text(
                                        child,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedChild = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Button to Open Full Safety Map & Geofence
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParentLiveMapScreen(
                            guardian: widget.guardian,
                            bus: assignedBus,
                            route: assignedRoute,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.radar_rounded, size: 20),
                    label: const Text(
                      "OPEN LIVE SAFETY MAP & GEOFENCE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Real-Time Verified Journey Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), // Emerald light
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Confirmed Boarding Status",
                              style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Your child boarded Bus 12 at 07:39 AM at Madhavapatnam Stop. Verified by driver M. S. Prasad via secure QR scanning.",
                              style: TextStyle(color: Color(0xFF047857), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Assigned Bus Live Tracking
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
                          "Driver: ${assignedBus.assignedDriverName ?? 'Prasad'} (AP-05-TJ-1012)",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    StatusBadge(status: assignedBus.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Map View
                SizedBox(
                  height: 300,
                  child: LiveMapWidget(
                    selectedBus: assignedBus,
                    selectedRoute: assignedRoute,
                    showAllFleet: false,
                  ),
                ),

                const SizedBox(height: 16),

                // Expected College Arrival
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: AppColors.primaryNavy),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Expected Campus Arrival", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Aditya Campus Main Gate", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Text("08:04 AM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Attendance History Records
                const Text(
                  "Recent Attendance History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _buildHistoryRow("Today, 07:39 AM", "Bus 12 (Boarded)", "Madhavapatnam Bypass", Colors.green),
                      const Divider(height: 1),
                      _buildHistoryRow("Yesterday, 04:45 PM", "Bus 12 (Dropped)", "Madhavapatnam Bypass", Colors.blue),
                      const Divider(height: 1),
                      _buildHistoryRow("Yesterday, 07:41 AM", "Bus 12 (Boarded)", "Madhavapatnam Bypass", Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryRow(String time, String bus, String stop, Color statusColor) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 10, color: statusColor),
      title: Text(bus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(stop, style: const TextStyle(fontSize: 11)),
      trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

