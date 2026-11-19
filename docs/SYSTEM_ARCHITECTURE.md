# Smart Campus Transport: System Architecture & Data Flow

## 1. High-Level System Architecture Diagram

```mermaid
flowchart TD
    subgraph MobileClients["Client Applications (Flutter)"]
        StudentApp["Student Mobile Portal<br/>(Live Map, ETA, QR Pass, Missed Bus)"]
        ParentApp["Guardian Mobile Portal<br/>(Live Child Bus Tracking, Verified Alerts)"]
        DriverApp["Driver Application<br/>(Foreground GPS, Trip Mgmt, QR Scanner, SOS)"]
        WebAdmin["Control Room Web Dashboard<br/>(Fleet Map, Incident Dispatch, Route Optimizer)"]
    end

    subgraph FirebaseBackend["Firebase Backend (Spark Tier - ₹0 Infrastructure)"]
        FirebaseAuth["Firebase Authentication<br/>(Custom Role Claims: Admin, Coord, Driver, Student, Parent)"]
        FirestoreDB["Cloud Firestore (Institutional Store)<br/>Users, Routes, Stops, Trips, Attendance, Incidents"]
        RealtimeDB["Firebase Realtime Database (Streaming)<br/>liveLocations/{busId}, activeTrips, activeIncidents"]
        FCM["Firebase Cloud Messaging<br/>(Proximity Alerts, Emergency SOS, Announcements)"]
    end

    subgraph CoreEngines["Core Computational & Research Engines"]
        GpsSmoother["GPS Validator & Smoother<br/>(Accuracy Check, Jump Rejection, EMA)"]
        EtaEngine["Predictive ETA Engine<br/>(Method A: Baseline vs Method B: Multi-Factor)"]
        RoutingEngine["Route Optimization Engine<br/>(Dijkstra & A* Pathfinding)"]
        RescueRanker["Breakdown Rescue Ranker<br/>(MAUT Utility Model & Capacity Constraints)"]
        AttendanceCrypto["Cryptographic Attendance Engine<br/>(HMAC SHA256 Replay-Resistant QR + Geofencing)"]
    end

    DriverApp -->|3-5s Telemetry Fixes| GpsSmoother
    GpsSmoother -->|Validated Live Coordinates| RealtimeDB
    DriverApp -->|Scanned QR Token| AttendanceCrypto
    AttendanceCrypto -->|Verified Boarding Record| FirestoreDB

    RealtimeDB -->|Low-Latency LatLng Stream| StudentApp
    RealtimeDB -->|Live Vehicle Stream| ParentApp
    RealtimeDB -->|Fleet Realtime Positions| WebAdmin

    FirestoreDB -->|Trip & Student Details| StudentApp
    FirestoreDB -->|Verified Journey Logs| ParentApp
    FirestoreDB -->|Fleet Config & Emergency Incidents| WebAdmin

    WebAdmin -->|Trigger Rescue Dispatch| RescueRanker
    RescueRanker -->|Ranked Alternative Buses| RealtimeDB
    
    DriverApp -->|Emergency SOS Trigger| RealtimeDB
    RealtimeDB -->|Instant Alarm Broadcast| WebAdmin
    WebAdmin -->|Push Alerts| FCM
    FCM -->|Critical Notifications| ParentApp
```

---

## 2. Sequence Diagram: Emergency Breakdown & Capacity-Aware Rescue Dispatch

```mermaid
sequenceDiagram
    autonumber
    actor Driver as Broken Bus Driver
    participant App as Driver Mobile App
    participant RTDB as Firebase Realtime DB
    participant Coord as Transport Coordinator
    participant Ranker as MAUT Rescue Engine
    participant ResBus as Rescue Bus Driver
    actor Student as Stranded Students / Parents

    Driver->>App: Report Breakdown (Engine Failure, 27 Passengers)
    App->>RTDB: Write activeIncidents/{incId} (Status: Reported)
    RTDB-->>Coord: Instant High-Priority Incident Alert on Control Dashboard
    Coord->>Ranker: Request Rescue Candidates for Bus 31 (27 Students)
    Ranker->>Ranker: Filter Operating Fleet by Spare Capacity >= 27
    Ranker->>Ranker: Score Candidates via Distance, Spare Seats & Route Convergence
    Ranker-->>Coord: Returns Ranked List (Top: Bus 07 with 28 spare seats, ETA: 7 mins)
    Coord->>RTDB: Approve & Dispatch Rescue Bus 07
    RTDB-->>ResBus: Push Rescue Assignment Route Order
    RTDB-->>Student: Push Notification: "Rescue Bus 07 dispatched. ETA: 7 mins"
    ResBus->>Driver: Arrive at breakdown site & verify passenger transfer
    Driver->>RTDB: Incident Resolved & Logged
```

---

## 3. Sequence Diagram: Replay-Resistant QR Attendance & Parent Notification

```mermaid
sequenceDiagram
    autonumber
    actor Student as Student (Aditya Varma)
    participant StudentApp as Student Mobile App
    actor Driver as Bus Driver (M. S. Prasad)
    participant DriverApp as Driver App (QR Scanner)
    participant Engine as Attendance Service
    participant Firestore as Cloud Firestore
    actor Parent as Guardian (Suryanarayana Varma)

    Student->>StudentApp: Open "My Boarding Pass"
    StudentApp->>StudentApp: Generate HMAC-SHA256 Token (15-min expiry)
    StudentApp-->>Student: Display Dynamic Signed QR Code
    Driver->>DriverApp: Scan Student QR Code
    DriverApp->>Engine: Validate Token Signature, Expiration & Stop Proximity
    Engine->>Engine: Check Duplicate Cache for trip_01_student_001
    alt Token Valid & No Duplicate
        Engine->>Firestore: Write verified attendance (Status: Boarded)
        Firestore-->>DriverApp: Visual Confirmation ("Boarding Verified")
        Firestore-->>Parent: Push Alert: "Your child boarded Bus 12 at 07:39 AM"
    else Expired or Duplicate
        Engine-->>DriverApp: Display Rejection Warning with Reason
    end
```

---

## 4. Google Maps-Style Live Navigation & Dynamic Road Rerouting Architecture

```mermaid
flowchart TD
    subgraph DriverDevice["Driver Mobile Device"]
        GPSFix["Android GPS Hardware<br/>(3-5s sampling, ±4m accuracy)"]
        NavUI["Google Maps-Style Navigation UI<br/>(Turn Maneuver Card, Speed Indicator, 3D View)"]
        VoiceEngine["Web Speech API / Audio Guidance<br/>('In 250m turn left on Hospital Road')"]
    end

    subgraph NavEngine["Navigation & Geometry Engine (backend_telemetry_engine.js)"]
        KinematicJumpFilter["Kinematic Jump Filter<br/>(v < 38 m/s, device timestamp aware)"]
        PerpendicularDistance["Point-to-Segment Corridor Distance<br/>(Perpendicular drop to road vector)"]
        DeviationDetector{"Sustained Deviation?<br/>(> 150m for 2+ consecutive updates)"}
        DynamicReroute["Dynamic Road Rerouting Engine<br/>(Connects detour to next mandatory stop,<br/>preserving all remaining stops)"]
        TurnManeuverSelector["Upcoming Maneuver Selector<br/>(Distance to next turn, street name, next road)"]
    end

    subgraph CloudState["Authoritative Cloud Sync (Firebase RTDB Spark ₹0)"]
        RTDBLive["liveLocations/{busId}<br/>(Heading, Speed, Freshness, Current Maneuver)"]
        RTDBTrips["activeTrips/{tripId}<br/>(Active stop index, remaining polylines)"]
        RTDBIncidents["activeIncidents/{incId}<br/>(Route deviation alert dispatched to Admin)"]
    end

    subgraph ClientViewers["Synchronized Multi-App Live Viewers"]
        StudentView["Student Portal<br/>(Pulsing Pickup Beacon, Dual Polylines,<br/>Draggable Predictive ETA Sheet)"]
        ParentView["Guardian Portal<br/>(Multi-Child Switcher, Synchronized Bus Stream,<br/>Verified Boarding Alerts)"]
        AdminView["Admin Control Room<br/>(Fleet Map, Active Deviations, Rescue Dispatch)"]
    end

    GPSFix --> KinematicJumpFilter
    KinematicJumpFilter --> PerpendicularDistance
    PerpendicularDistance --> DeviationDetector
    DeviationDetector -->|No: On Road Corridor| TurnManeuverSelector
    DeviationDetector -->|Yes: Off Corridor Detour| DynamicReroute
    DynamicReroute --> RTDBIncidents
    DynamicReroute --> TurnManeuverSelector
    TurnManeuverSelector --> NavUI
    TurnManeuverSelector --> VoiceEngine
    TurnManeuverSelector --> RTDBLive
    TurnManeuverSelector --> RTDBTrips

    RTDBLive --> StudentView
    RTDBLive --> ParentView
    RTDBLive --> AdminView
```

### Key Technical Properties:
1. **Kinematic Jump & Temporal Filtering:** Rejects non-physical coordinate jumps (> 38 m/s / 136 km/h) while calculating elapsed time using physical device timestamps to prevent false rejections during high-frequency network arrivals.
2. **Shortest Valid Road Corridor:** Each route is backed by real OSM road coordinates, scheduled stops, and turn maneuver waypoints with actual street names.
3. **Sustained Deviation & Dynamic Road Rerouting:**
   - Single GPS outliers (< 150m or single jitter) do not trigger unnecessary rerouting.
   - Sustained deviation (> 150m for 2 or more consecutive fixes) activates the dynamic reroute engine.
   - The rerouted path connects the bus's detour position to the *next required mandatory stop*, strictly preserving all downstream intermediate stops so no boarding student is ever missed.
4. **Zero-Cost Multi-App Synchronization:** All applications (Driver, Student, Parent, Admin) subscribe to the unified authoritative Firebase Realtime Database node (`liveLocations/{busId}`), guaranteeing sub-second visual consistency at ₹0 infrastructure cost on the Firebase Spark tier.


