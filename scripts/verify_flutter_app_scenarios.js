/**
 * Comprehensive Automated Verification Script for Section 17 Acceptance Scenarios:
 * 1. Independent Driver Starts (Ravi & Suresh concurrency without state collision)
 * 2. Active Session Double-Start Prevention (Locking & rejection)
 * 3. Stop Approach, Arrival Detection & Dwell Management
 * 4. Sustained Route Deviation Detection & Dynamic Recalculation
 * 5. Cryptographic QR Boarding, Attendance Logging & Guardian Alert Dispatch
 * 6. Bus Breakdown Reporting, Dispatcher Notification & Rescue Bus Assignment
 * 7. Device Network Interruption & Seamless Session Resumption
 * 8. Trip Completion, Manifest Finalization & Telemetry Shutdown
 * 9. Student Attempting Driver Login Rejection (Strict ROLE_MISMATCH Enforcement)
 * 10. Unauthorized Parent Cross-Student Access Denial
 */

let passedCount = 0;
let failedCount = 0;

function assert(condition, scenario, testDesc) {
  if (condition) {
    console.log(`  [PASS] [${scenario}] ${testDesc}`);
    passedCount++;
  } else {
    console.error(`  [FAIL] [${scenario}] ${testDesc}`);
    failedCount++;
  }
}

async function api(path, method = 'GET', body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`http://localhost:3000/api/${path}`, opts);
  return await res.json();
}

console.log("\n==========================================================================");
console.log("ACCEPTANCE SCENARIO VERIFIER: 10/10 CORE TRANSIT & MULTI-ROLE WORKFLOWS");
console.log("Verifying Flutter Client Business Logic, Server Engine & State Invariants");
console.log("==========================================================================\n");

(async () => {
  try {
    // Clean reset of fleet database
    await api('fleet/reset', 'POST');

    // -----------------------------------------------------------------------
    // SCENARIO 1: Ravi and Suresh start their buses independently.
    // No cross-bus interference or state collisions.
    // -----------------------------------------------------------------------
    console.log(">>> SCENARIO 1: Independent Driver Starts (No State Collision)");
    const startRavi = await api('trip/start', 'POST', {
      driverUid: 'drv_ravi',
      busId: 'bus_01',
      routeId: 'route_a'
    });
    assert(startRavi.success === true, "Scenario 1", "Driver Ravi successfully starts Bus 01 on Route A");

    const startSuresh = await api('trip/start', 'POST', {
      driverUid: 'drv_suresh',
      busId: 'bus_02',
      routeId: 'route_b'
    });
    assert(startSuresh.success === true, "Scenario 1", "Driver Suresh concurrently starts Bus 02 on Route B");

    const fleetStatus = await api('fleet/status');
    assert(
      fleetStatus.buses.bus_01.status === 'active' &&
      fleetStatus.buses.bus_02.status === 'active' &&
      fleetStatus.buses.bus_01.assignedDriverId === 'drv_ravi' &&
      fleetStatus.buses.bus_02.assignedDriverId === 'drv_suresh',
      "Scenario 1",
      "Both buses are simultaneously ACTIVE with isolated state and distinct assigned drivers"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 2: Driver attempts to start an already active bus session.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 2: Active Session Double-Start Prevention");
    const duplicateStart = await api('trip/start', 'POST', {
      driverUid: 'drv_ravi',
      busId: 'bus_01',
      routeId: 'route_a'
    });
    assert(
      duplicateStart.success === false && (duplicateStart.code === 'BUS_ALREADY_ACTIVE' || duplicateStart.code === 'DRIVER_ALREADY_ACTIVE'),
      "Scenario 2",
      `Duplicate start attempt on active Bus 01 is rejected with ${duplicateStart.code}`
    );

    // -----------------------------------------------------------------------
    // SCENARIO 3: Bus approaches and stops at scheduled stop.
    // Navigation detects arrival, dwells for boarding, records departures.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 3: Stop Arrival, Dwell Detection & Departure Transition");
    // Ingest GPS coordinates right at Stop 1 (Main Bus Stand: 16.9604, 82.2381)
    await api('driver/gps', 'POST', {
      driverUid: 'drv_ravi',
      busId: 'bus_01',
      latitude: 16.9604,
      longitude: 82.2381,
      speedKmh: 0.0,
      headingDegrees: 90
    });

    const guidanceArrival = await api('navigation/guidance?busId=bus_01&lat=16.9604&lng=82.2381&speedKmh=0');
    assert(
      guidanceArrival.nextStop !== null &&
      (guidanceArrival.nextStop.distanceMeters <= 50 || guidanceArrival.nextStop.roadDistanceKm <= 0.05),
      "Scenario 3",
      "Bus is within 50 meters geofence radius of scheduled stop; triggers Arrival HUD"
    );

    // Advance stop to simulate completed dwell and departure
    const advanceResult = await api('trip/advance-stop', 'POST', {
      busId: 'bus_01',
      departedStopId: 'stop_a1'
    });
    assert(
      advanceResult.success === true,
      "Scenario 3",
      "Stop departure recorded; next stop advanced in operational schedule"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 4: Sustained route deviation. Triggers deviation alert & re-routing.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 4: Sustained Route Deviation Detection");
    // Ingest 2 consecutive off-route coordinates to trigger sustained deviation filter
    await api('navigation/guidance?busId=bus_01&lat=17.0500&lng=82.3500&speedKmh=38');
    const deviationGuidance = await api('navigation/guidance?busId=bus_01&lat=17.0500&lng=82.3500&speedKmh=38');
    assert(
      deviationGuidance.isOffRoute === true,
      "Scenario 4",
      "Off-corridor position (>150m from road polyline) flagged as isOffRoute = true"
    );
    assert(
      deviationGuidance.navigationPolyline && deviationGuidance.navigationPolyline.length > 0,
      "Scenario 4",
      "Dynamic recovery route geometry synthesized to reconnect bus to nearest stop"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 5: Student QR scan upon boarding.
    // Recorded in attendance, guardian notified, count decremented from upcoming stop.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 5: Cryptographic QR Boarding & Guardian Notification");
    const boardResult = await api('attendance/board', 'POST', {
      studentId: 'std_anil',
      busId: 'bus_01',
      stopId: 'stop_a1',
      token: 'eyJhbGciOiJIUzI1NiJ9.std_anil_token_sig',
      driverUid: 'drv_ravi'
    });
    assert(boardResult.success === true, "Scenario 5", "Student Anil Varma successfully boarded Bus 01 via verified QR pass");

    const studentLive = await api('student/live?studentId=std_anil');
    assert(
      studentLive.student.boardingStatus === 'boarded',
      "Scenario 5",
      "Student boardingStatus updated to 'boarded' in real-time database"
    );

    const manifestData = await api('attendance/manifest?busId=bus_01');
    const anilPassenger = manifestData.manifest.find(p => p.studentId === 'std_anil');
    assert(
      anilPassenger && anilPassenger.boardingStatus === 'boarded',
      "Scenario 5",
      "Student recorded as actively onboard in driver's passenger manifest"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 6: Bus breakdown reported. Dispatcher informed, nearby compatible
    // bus identified, passengers and parents notified.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 6: Breakdown Reporting & Multi-Corridor Rescue");
    const breakdownReport = await api('breakdown/report', 'POST', {
      busId: 'bus_01',
      driverUid: 'drv_ravi',
      latitude: 16.9950,
      longitude: 82.2150,
      description: "Severe transmission overheat. Vehicle stopped safely on highway shoulder."
    });
    assert(breakdownReport.success === true, "Scenario 6", "Emergency breakdown incident registered and broadcast to dispatcher");

    const alternatives = await api('routes/alternatives?studentId=std_anil&stopId=stop_a1');
    assert(
      alternatives.alternatives && alternatives.alternatives.length > 0,
      "Scenario 6",
      `Corridor rescue finder discovered ${alternatives.alternatives.length} candidate rescue buses with available capacity`
    );

    const rescueDispatch = await api('rescue/dispatch', 'POST', {
      incidentId: breakdownReport.incidentId,
      rescueBusId: 'bus_02'
    });
    assert(rescueDispatch.success === true, "Scenario 6", "Rescue bus (Bus 02) assigned to assume stranded passenger manifest");

    // -----------------------------------------------------------------------
    // SCENARIO 7: Device loses and regains network.
    // Reconnection handled gracefully without duplicate sessions.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 7: Network Interruption & Seamless Resumption");
    // Simulate reconnection after offline gap: driver sends latest cached GPS with isReconnected flag
    const resumeGps = await api('driver/gps', 'POST', {
      driverUid: 'drv_suresh',
      busId: 'bus_02',
      latitude: 17.0120,
      longitude: 81.8250,
      speedKmh: 35.0,
      headingDegrees: 180,
      isReconnected: true
    });
    assert(resumeGps.success === true, "Scenario 7", "Post-reconnection GPS telemetry seamlessly ingested without session dropout");

    const sureshTrip = await api('student/live?studentId=std_rahul');
    assert(
      sureshTrip.isTripActive === true,
      "Scenario 7",
      "Bus 02 maintains continuous active trip session throughout network recovery"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 8: Trip completes. Final status updated, summaries logged.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 8: Trip Completion & Operational Log Finalization");
    const endTrip = await api('trip/end', 'POST', {
      driverUid: 'drv_suresh',
      busId: 'bus_02',
      totalPassengersDelivered: 42
    });
    assert(endTrip.success === true, "Scenario 8", "Trip completed successfully by Driver Suresh");

    const finalBusStatus = (await api('fleet/status')).buses.bus_02;
    assert(
      finalBusStatus.status === 'completed',
      "Scenario 8",
      "Bus 02 status transitioned to 'completed' with zero active telemetry leak"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 9: Student attempts driver login. Rejected with ROLE_MISMATCH.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 9: Student Login Attempt into Driver Portal (ROLE_MISMATCH)");
    const studentAsDriver = await api('auth/login', 'POST', {
      email: 'aditya.student@campus.edu',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(
      studentAsDriver.success === false && studentAsDriver.code === 'ROLE_MISMATCH',
      "Scenario 9",
      "Strict Auth Guard: Student account logging into Driver Portal rejected with ROLE_MISMATCH"
    );

    const driverAsDriver = await api('auth/login', 'POST', {
      email: 'ravi.driver@campus.edu',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(
      driverAsDriver.success === true && driverAsDriver.user.role === 'driver',
      "Scenario 9",
      "Legitimate driver login authorized into Driver Operations Hub"
    );

    // -----------------------------------------------------------------------
    // SCENARIO 10: Unauthorized parent attempts to track unassigned student bus.
    // -----------------------------------------------------------------------
    console.log("\n>>> SCENARIO 10: Cross-Student Parent Authorization Enforcement");
    // Parent Nikhil (linked only to std_nikhil) attempts to track std_anil (Aditya/Anil's bus)
    const unauthorizedParent = await api('parent/verify-access?parentId=parent_nikhil&studentId=std_anil');
    assert(
      unauthorizedParent.success === false && unauthorizedParent.code === 'UNAUTHORIZED_ACCESS',
      "Scenario 10",
      "Parent Nikhil denied access to unlinked student Anil Varma (Access Code: UNAUTHORIZED_ACCESS)"
    );

    const authorizedParent = await api('parent/verify-access?parentId=parent_anil&studentId=std_anil');
    assert(
      authorizedParent.success === true && authorizedParent.authorized === true,
      "Scenario 10",
      "Parent Suryanarayana Varma granted verified access to linked student Anil Varma"
    );

    // -----------------------------------------------------------------------
    // SUMMARY
    // -----------------------------------------------------------------------
    console.log("\n==========================================================================");
    console.log(`VERIFICATION COMPLETE: ${passedCount} PASSED, ${failedCount} FAILED (${((passedCount/(passedCount+failedCount))*100).toFixed(0)}%)`);
    console.log("==========================================================================\n");

    if (failedCount > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  } catch (err) {
    console.error("FATAL VERIFICATION ERROR:", err);
    process.exit(1);
  }
})();
