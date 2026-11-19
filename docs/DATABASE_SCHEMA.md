# Smart Campus Transport: Database Schema & Security Architecture

## 1. Firebase Realtime Database (Low-Latency Streaming)

The Realtime Database is dedicated exclusively to volatile telemetry and active emergency alerts to maximize speed and maintain ₹0 cost under the Firebase Spark free quota.

### Path: `/liveLocations/{busId}`
```json
{
  "latitude": 17.0180,
  "longitude": 82.1850,
  "speed": 36.5,
  "heading": 315.0,
  "accuracy": 4.5,
  "timestamp": 1731835200000,
  "isSimulation": false
}
```

### Path: `/activeTrips/{tripId}`
```json
{
  "busId": "bus_01",
  "driverId": "driver_b1",
  "routeId": "route_01",
  "status": "in_progress",
  "currentStopIndex": 2,
  "boardedCount": 38,
  "startTime": 1731834000000
}
```

### Path: `/activeIncidents/{incidentId}`
```json
{
  "busId": "bus_05",
  "busNumber": "Bus 31",
  "driverId": "driver_b5",
  "category": "breakdown",
  "severity": "high",
  "status": "reported",
  "latitude": 17.1850,
  "longitude": 82.2150,
  "passengerCount": 27,
  "reportedAt": 1731835100000
}
```

---

## 2. Cloud Firestore (Institutional Records)

### Collection: `users/{userId}`
- `uid`: string (Primary key matching Firebase Auth UID)
- `email`: string
- `displayName`: string
- `phoneNumber`: string
- `role`: string (`super_admin` | `coordinator` | `driver` | `student` | `guardian`)
- `assignedBusId`: string?
- `assignedRouteId`: string?
- `assignedStopId`: string?
- `linkedStudentIds`: array of strings (for guardians)
- `department`: string
- `rollNumber`: string
- `isApproved`: boolean

### Collection: `buses/{busId}`
- `id`: string
- `busNumber`: string (e.g., "Bus 12")
- `registrationPlate`: string (e.g., "AP-05-TJ-1012")
- `totalCapacity`: number (e.g., 52)
- `occupiedSeats`: number
- `status`: string (`moving` | `stationary` | `delayed` | `offline` | `breakdown` | `emergency`)
- `assignedDriverId`: string
- `assignedDriverName`: string
- `assignedRouteId`: string
- `assignedRouteName`: string
- `fuelLevelPercentage`: number
- `odometerKm`: number

### Collection: `routes/{routeId}`
- `id`: string
- `routeCode`: string (e.g., "R-01")
- `routeName`: string (e.g., "Kakinada City Express")
- `startLocation`: string
- `endLocation`: string
- `totalDistanceKm`: number
- `estimatedDurationMinutes`: number
- `stops`: array of StopModel objects
- `polylineWaypoints`: array of {lat, lng} coordinates

### Collection: `attendance/{attendanceId}`
- `id`: string
- `tripId`: string
- `busId`: string
- `studentId`: string
- `studentName`: string
- `rollNumber`: string
- `stopId`: string
- `stopName`: string
- `status`: string (`boarded` | `dropped` | `absent` | `missed`)
- `timestamp`: timestamp
- `verifiedByDriverId`: string
- `verificationMethod`: string (`qr_code` | `driver_manual`)
- `isGeofenceVerified`: boolean
- `isManualCorrection`: boolean
- `correctionReason`: string?

### Collection: `incidents/{incidentId}`
- `id`: string
- `busId`: string
- `busNumber`: string
- `driverId`: string
- `driverName`: string
- `tripId`: string
- `category`: string (`breakdown` | `accident` | `medical` | `fire` | `security` | `other`)
- `severity`: string (`low` | `medium` | `high` | `critical`)
- `status`: string (`reported` | `acknowledged` | `assigned` | `resolved`)
- `latitude`: number
- `longitude`: number
- `description`: string
- `passengerCount`: number
- `reportedAt`: timestamp
- `acknowledgedAt`: timestamp?
- `acknowledgedBy`: string?
- `resolvedAt`: timestamp?
- `resolutionSummary`: string?

### Collection: `announcements/{announcementId}`
- `id`: string
- `title`: string
- `content`: string
- `category`: string (`holiday` | `delay` | `route_change` | `exam` | `emergency` | `general`)
- `targetRole`: string (`all` | `student` | `guardian` | `driver`)
- `targetRouteId`: string?
- `targetBusId`: string?
- `isUrgent`: boolean
- `createdAt`: timestamp

---

## 3. Security & Access Control Model

1. **Student Privacy Protection:** Students can only read their own profile, assigned bus live telemetry, and personal attendance history. Students cannot view other students' records.
2. **Guardian Access Bound to Verified Links:** Guardians can only query students whose IDs exist in `guardianStudentLinks/{guardianId_studentId}`.
3. **Driver Privilege Scoping:** Drivers can only submit verified attendance records for trips assigned to them. Drivers cannot write administrative records or modify other drivers' trips.
4. **Append-Only Audit Trail:** `auditLogs` collection enforces `allow update, delete: if false` in `firestore.rules`.

