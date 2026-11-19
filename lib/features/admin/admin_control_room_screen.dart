import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/models/bus_model.dart';
import '../../core/models/route_model.dart';
import '../../core/models/incident_model.dart';
import '../../core/algorithms/breakdown_ranker.dart';
import '../../core/services/simulation_service.dart';
import '../../core/services/emergency_service.dart';
import '../../core/services/attendance_service.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/live_map_widget.dart';
import '../../shared/stat_metric_card.dart';
import '../../shared/status_badge.dart';

class AdminControlRoomScreen extends StatefulWidget {
  final UserModel admin;
  final VoidCallback onOpenResearch;

  const AdminControlRoomScreen({
    super.key,
    required this.admin,
    required this.onOpenResearch,
  });

  @override
  State<AdminControlRoomScreen> createState() => _AdminControlRoomScreenState();
}

class _AdminControlRoomScreenState extends State<AdminControlRoomScreen> {
  final simulationService = SimulationService();
  final emergencyService = EmergencyService();
  final attendanceService = AttendanceService();

  BusModel? _selectedBus;
  int _selectedTabIndex = 0; // 0: Fleet Map & Live Overview, 1: Incidents & Breakdowns, 2: Routes & Fleet, 3: Analytics

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusModel>>(
      stream: simulationService.fleetStream,
      initialData: simulationService.buses,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? simulationService.buses;
        _selectedBus ??= buses.first;

        final movingCount = buses.where((b) => b.status == BusOperationalStatus.moving).length;
        final delayedCount = buses.where((b) => b.status == BusOperationalStatus.delayed).length;
        final breakdownCount = buses.where((b) => b.status == BusOperationalStatus.breakdown).length;
        final emergencyCount = buses.where((b) => b.status == BusOperationalStatus.emergency).length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.primaryNavy,
                title: Row(
                  children: [
                    const Icon(Icons.hub, color: AppColors.accentCyan),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isMobile ? "Control Room" : "Central Fleet Control Room",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: simulationService.isSimulationActive ? Colors.green[800] : Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        simulationService.isSimulationActive ? "SIM" : "GPS",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (simulationService.isSimulationActive) {
                          simulationService.stopSimulation();
                        } else {
                          simulationService.startSimulation();
                        }
                      });
                    },
                    icon: Icon(
                      simulationService.isSimulationActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: Colors.white,
                    ),
                    tooltip: "Toggle Simulator Engine",
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: widget.onOpenResearch,
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text("Research", style: TextStyle(fontSize: 12)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.science, color: Colors.white),
                      onPressed: widget.onOpenResearch,
                      tooltip: "Research Benchmarks",
                    ),
                  const SizedBox(width: 8),
                ],
              ),
              bottomNavigationBar: isMobile
                  ? NavigationBar(
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
                      backgroundColor: AppColors.secondaryNavy,
                      indicatorColor: AppColors.primaryBlue,
                      destinations: const [
                        NavigationDestination(icon: Icon(Icons.map, color: Colors.white70), selectedIcon: Icon(Icons.map, color: Colors.white), label: "Fleet"),
                        NavigationDestination(icon: Icon(Icons.warning_amber, color: Colors.white70), selectedIcon: Icon(Icons.warning_amber, color: Colors.white), label: "Alerts"),
                        NavigationDestination(icon: Icon(Icons.directions_bus, color: Colors.white70), selectedIcon: Icon(Icons.directions_bus, color: Colors.white), label: "Routes"),
                        NavigationDestination(icon: Icon(Icons.analytics, color: Colors.white70), selectedIcon: Icon(Icons.analytics, color: Colors.white), label: "KPIs"),
                      ],
                    )
                  : null,
              body: Row(
                children: [
                  if (!isMobile) ...[
                    NavigationRail(
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
                      backgroundColor: AppColors.secondaryNavy,
                      selectedIconTheme: const IconThemeData(color: AppColors.accentCyan),
                      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
                      selectedLabelTextStyle: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.map), label: Text("Fleet Map")),
                        NavigationRailDestination(icon: Icon(Icons.warning_amber), label: Text("Incidents")),
                        NavigationRailDestination(icon: Icon(Icons.directions_bus), label: Text("Fleet & Routes")),
                        NavigationRailDestination(icon: Icon(Icons.analytics), label: Text("Analytics")),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: AppColors.lightNavy),
                  ],

                  // Main Module Content
                  Expanded(
                    child: _buildCurrentModule(buses, movingCount, delayedCount, breakdownCount, emergencyCount, isMobile),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentModule(
    List<BusModel> buses,
    int movingCount,
    int delayedCount,
    int breakdownCount,
    int emergencyCount,
    bool isMobile,
  ) {
    switch (_selectedTabIndex) {
      case 1:
        return _buildIncidentsModule(buses);
      case 2:
        return _buildFleetAndRoutesModule(buses);
      case 3:
        return _buildAnalyticsModule(buses);
      default:
        return _buildFleetOverviewAndMap(buses, movingCount, delayedCount, breakdownCount, emergencyCount, isMobile);
    }
  }

  Widget _buildFleetOverviewAndMap(
    List<BusModel> buses,
    int movingCount,
    int delayedCount,
    int breakdownCount,
    int emergencyCount,
    bool isMobile,
  ) {
    final metricCards = [
      StatMetricCard(
        title: "Total Fleet",
        value: "${buses.length}",
        subtitle: "$movingCount moving on routes",
        icon: Icons.directions_bus,
        accentColor: AppColors.primaryBlue,
      ),
      StatMetricCard(
        title: "Delayed Buses",
        value: "$delayedCount",
        subtitle: "Traffic / Bridge detour",
        icon: Icons.access_time_filled,
        accentColor: AppColors.statusDelayed,
      ),
      StatMetricCard(
        title: "Breakdown Alert",
        value: "$breakdownCount",
        subtitle: breakdownCount > 0 ? "Requires rescue dispatch" : "Fleet operational",
        icon: Icons.build,
        accentColor: AppColors.statusBreakdown,
      ),
      StatMetricCard(
        title: "Active Emergencies",
        value: "$emergencyCount",
        subtitle: emergencyCount > 0 ? "HIGH PRIORITY SOS" : "Zero active SOS",
        icon: Icons.emergency,
        accentColor: AppColors.statusEmergency,
      ),
    ];

    Widget metricsWidget;
    if (isMobile) {
      metricsWidget = Column(
        children: [
          Row(
            children: [
              Expanded(child: metricCards[0]),
              const SizedBox(width: 10),
              Expanded(child: metricCards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: metricCards[2]),
              const SizedBox(width: 10),
              Expanded(child: metricCards[3]),
            ],
          ),
        ],
      );
    } else {
      metricsWidget = Row(
        children: metricCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    }

    final mapWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Live Fleet Positioning (Campus & District Corridor)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isMobile ? 320 : 520,
          child: LiveMapWidget(
            fleet: buses,
            selectedBus: _selectedBus,
            selectedRoute: simulationService.routes.firstWhere(
              (r) => r.id == (_selectedBus?.assignedRouteId ?? 'route_01'),
              orElse: () => simulationService.routes.first,
            ),
            showAllFleet: true,
          ),
        ),
      ],
    );

    final busListWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Active Vehicles",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          height: isMobile ? 280 : 520,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ListView.separated(
            itemCount: buses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final bus = buses[idx];
              final isSelected = _selectedBus?.id == bus.id;
              return ListTile(
                selected: isSelected,
                selectedTileColor: AppColors.primaryBlue.withOpacity(0.08),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bus.status.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_bus, color: bus.status.color, size: 20),
                ),
                title: Text(bus.busNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(
                  "${bus.assignedRouteName} • Driver: ${bus.assignedDriverName}",
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(status: bus.status, compact: true),
                    const SizedBox(height: 4),
                    Text(
                      "${bus.occupiedSeats}/${bus.totalCapacity} seats",
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() => _selectedBus = bus);
                },
              );
            },
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          metricsWidget,
          const SizedBox(height: 18),
          if (isMobile) ...[
            mapWidget,
            const SizedBox(height: 18),
            busListWidget,
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: mapWidget),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: busListWidget),
              ],
            ),
          ],
        ],
      ),
    );
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsModule(List<BusModel> buses) {
    final incidents = emergencyService.incidents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Emergency Incident & Breakdown Response Management",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            "Evaluate active emergencies and utilize the Multi-Attribute Utility Theory (MAUT) algorithm to dispatch optimal nearby rescue buses.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          if (incidents.isEmpty)
            const Center(child: Text("No active incidents reported. All vehicles normal."))
          else
            ...incidents.map((incident) {
              final isBreakdown = incident.category == IncidentCategory.breakdown;

              // Generate candidate buses for ranking
              final candidateFleet = buses
                  .where((b) => b.id != incident.busId)
                  .map((b) => CandidateBus(
                        busId: b.id,
                        busNumber: b.busNumber,
                        driverId: b.assignedDriverId ?? 'driver',
                        driverName: b.assignedDriverName ?? 'Driver',
                        currentLatitude: b.liveLocation?.latitude ?? 17.0500,
                        currentLongitude: b.liveLocation?.longitude ?? 82.1500,
                        totalCapacity: b.totalCapacity,
                        occupiedSeats: b.occupiedSeats,
                        currentRouteId: b.assignedRouteId ?? 'route_01',
                      ))
                  .toList();

              final rankedCandidates = BreakdownAssistanceRanker.rankCandidates(
                breakdownLatitude: incident.latitude,
                breakdownLongitude: incident.longitude,
                strandedPassengerCount: incident.passengerCount,
                brokenBusRouteId: 'route_05',
                candidateFleet: candidateFleet,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isBreakdown ? Icons.build : Icons.emergency,
                                color: isBreakdown ? Colors.orange : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${incident.category.label}: ${incident.busNumber}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: incident.status == IncidentStatus.resolved ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              incident.status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: incident.status == IncidentStatus.resolved ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Description: ${incident.description}", style: const TextStyle(fontSize: 13)),
                      Text("Stranded Passengers: ${incident.passengerCount} Students", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Divider(height: 20),

                      // Ranked Candidate Buses Section
                      const Text(
                        "Algorithmic Rescue Recommendations (Ranked by Distance, Spare Seats & ETA):",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 8),
                      ...rankedCandidates.take(2).map((cand) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cand.isCapacityFeasible ? AppColors.borderLight : Colors.red.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${cand.bus.busNumber} (Driver: ${cand.bus.driverName})",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "Distance: ${(cand.distanceMeters / 1000).toStringAsFixed(1)} km • ETA: ~${cand.estimatedArrivalMinutes.toStringAsFixed(0)} mins",
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    cand.compatibilityReason,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cand.isCapacityFeasible ? Colors.green[800] : Colors.red[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cand.isCapacityFeasible ? AppColors.primaryNavy : Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: cand.isCapacityFeasible
                                    ? () {
                                        emergencyService.dispatchAssistance(
                                          incidentId: incident.id,
                                          brokenBusId: incident.busId,
                                          brokenBusNumber: incident.busNumber,
                                          replacementBusId: cand.bus.busId,
                                          replacementBusNumber: cand.bus.busNumber,
                                          coordinatorId: widget.admin.uid,
                                          passengerCount: incident.passengerCount,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Rescue bus ${cand.bus.busNumber} dispatched for ${incident.busNumber}!")),
                                        );
                                        setState(() {});
                                      }
                                    : null,
                                child: const Text("Dispatch Rescue", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFleetAndRoutesModule(List<BusModel> buses) {
    final routes = simulationService.routes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Campus Routes & Scheduled Stops Management",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ...routes.map((route) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(route.routeCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ),
                title: Text(route.routeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${route.startLocation} ➔ ${route.endLocation} • ${route.totalDistanceKm} km (~${route.estimatedDurationMinutes} mins)"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Scheduled Stops & Registered Boarding Students:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...route.stops.map((s) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(child: Text("${s.sequenceOrder}. ${s.name} (${s.scheduledPickupTime})", style: const TextStyle(fontSize: 12))),
                                Text("${s.registeredStudentCount} students", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsModule(List<BusModel> buses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fleet Analytics & Transport Sustainability Indicators",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: StatMetricCard(
                  title: "Fleet Punctuality",
                  value: "94.2%",
                  subtitle: "+3.1% improved via Predictive ETA",
                  icon: Icons.check_circle,
                  accentColor: Colors.green,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: StatMetricCard(
                  title: "Total Distance Today",
                  value: "142.5 km",
                  subtitle: "5 active corridors",
                  icon: Icons.route,
                  accentColor: AppColors.primaryBlue,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: StatMetricCard(
                  title: "Estimated Fuel Used",
                  value: "35.6 L",
                  subtitle: "~4.0 km/L fleet efficiency",
                  icon: Icons.local_gas_station,
                  accentColor: Colors.orange,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: StatMetricCard(
                  title: "Carbon Offset vs Cars",
                  value: "186 kg CO₂",
                  subtitle: "Consolidated bus pooling",
                  icon: Icons.eco,
                  accentColor: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

