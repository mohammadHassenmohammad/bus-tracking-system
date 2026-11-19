import 'dart:async';
import '../models/incident_model.dart';
import '../models/announcement_model.dart';
import '../algorithms/breakdown_ranker.dart';
import 'simulation_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal() {
    _initializeSeedIncidents();
  }

  final List<IncidentModel> _incidents = [];
  final List<BreakdownAssistanceRequest> _assistanceRequests = [];

  final _incidentStreamController = StreamController<List<IncidentModel>>.broadcast();
  Stream<List<IncidentModel>> get incidentStream => _incidentStreamController.stream;

  List<IncidentModel> get incidents => List.unmodifiable(_incidents);
  List<BreakdownAssistanceRequest> get assistanceRequests => List.unmodifiable(_assistanceRequests);

  void _initializeSeedIncidents() {
    _incidents.add(
      IncidentModel(
        id: 'inc_001',
        busId: 'bus_05',
        busNumber: 'Bus 31 (Rural)',
        driverId: 'driver_b5',
        driverName: 'G. Appa Rao',
        tripId: 'trip_05',
        category: IncidentCategory.breakdown,
        severity: IncidentSeverity.high,
        status: IncidentStatus.reported,
        latitude: 17.1850,
        longitude: 82.2150,
        description: 'Engine overheating on NH16 bypass near Prathipadu',
        passengerCount: 27,
        reportedAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    );
  }

  /// Triggers an immediate Emergency SOS alert from a driver
  Future<IncidentModel> triggerSos({
    required String busId,
    required String busNumber,
    required String driverId,
    required String driverName,
    required String tripId,
    required IncidentCategory category,
    required IncidentSeverity severity,
    required double latitude,
    required double longitude,
    required String description,
    required int passengerCount,
  }) async {
    final incident = IncidentModel(
      id: "inc_${DateTime.now().millisecondsSinceEpoch}",
      busId: busId,
      busNumber: busNumber,
      driverId: driverId,
      driverName: driverName,
      tripId: tripId,
      category: category,
      severity: severity,
      status: IncidentStatus.reported,
      latitude: latitude,
      longitude: longitude,
      description: description,
      passengerCount: passengerCount,
      reportedAt: DateTime.now(),
    );

    _incidents.insert(0, incident);
    _incidentStreamController.add(_incidents);

    // Update fleet simulation status
    SimulationService().injectEmergency(busId);
    return incident;
  }

  /// Evaluates active candidate buses for breakdown assistance using MAUT
  List<RankedAssistanceCandidate> findAssistanceCandidates({
    required IncidentModel incident,
    required List<CandidateBus> fleet,
  }) {
    return BreakdownAssistanceRanker.rankCandidates(
      breakdownLatitude: incident.latitude,
      breakdownLongitude: incident.longitude,
      strandedPassengerCount: incident.passengerCount,
      brokenBusRouteId: 'route_05',
      candidateFleet: fleet,
    );
  }

  /// Coordinator assigns a ranked candidate bus for passenger rescue
  Future<BreakdownAssistanceRequest> dispatchAssistance({
    required String incidentId,
    required String brokenBusId,
    required String brokenBusNumber,
    required String replacementBusId,
    required String replacementBusNumber,
    required String coordinatorId,
    required int passengerCount,
  }) async {
    final req = BreakdownAssistanceRequest(
      id: "req_${DateTime.now().millisecondsSinceEpoch}",
      incidentId: incidentId,
      brokenBusId: brokenBusId,
      brokenBusNumber: brokenBusNumber,
      assignedReplacementBusId: replacementBusId,
      assignedReplacementBusNumber: replacementBusNumber,
      passengerCount: passengerCount,
      status: 'approved',
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );

    _assistanceRequests.insert(0, req);

    // Update incident status
    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(
        status: IncidentStatus.assigned,
        acknowledgedAt: DateTime.now(),
        acknowledgedBy: coordinatorId,
      );
      _incidentStreamController.add(_incidents);
    }

    return req;
  }

  /// Resolves an incident
  void resolveIncident(String incidentId, String summary) {
    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(
        status: IncidentStatus.resolved,
        resolvedAt: DateTime.now(),
        resolutionSummary: summary,
      );
      _incidentStreamController.add(_incidents);
      SimulationService().resolveIncident(_incidents[idx].busId);
    }
  }
}

