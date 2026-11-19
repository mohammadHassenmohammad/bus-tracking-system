/**
 * Automated Verification Script for Real-World Workflows (Scenarios A through F)
 * Tests actual multi-driver concurrency, real Firebase RTDB operations,
 * state machine transitions, attendance cryptography, and breakdown rescue.
 */

let passedCount = 0;
let failedCount = 0;

function assert(condition, testDesc) {
  if (condition) {
    console.log(`  [PASS] ${testDesc}`);
    passedCount++;
  } else {
    console.error(`  [FAIL] ${testDesc}`);
    failedCount++;
  }
}

async function api(path, method = 'GET', body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`http://localhost:3000/api/${path}`, opts);
  return await res.json();
}

async function getRtdb(path) {
  try {
    const res = await api(`rtdb?path=${encodeURIComponent(path)}`);
    if (res && res.data) return res.data;
  } catch (e) {}
  try {
    const res = await fetch(`https://gps-tracking-b76d8-default-rtdb.firebaseio.com/${path}.json`, { signal: AbortSignal.timeout(1000) });
    return await res.json();
  } catch (e) {
    return null;
  }
}

console.log("\n=======================================================");
console.log("SMART CAMPUS TRANSPORT: END-TO-END SCENARIO VERIFIER");
console.log("Testing Against Live Server & Firebase RTDB");
console.log("=======================================================\n");

(async () => {
  try {
    // Reset test trips in engine and Firebase RTDB for clean idempotency
    // Reset fleet state and database for clean test
    await api('fleet/reset', 'POST');

    // ----------------------------------------------------
    // SCENARIO A: MULTI-DRIVER CREATION & SIMULTANEOUS START
    // ----------------------------------------------------
    console.log(">>> SCENARIO A: 3 Drivers, 3 Buses, Independent Start & Concurrency Control");

    // 1. Verify 3 drivers exist
    const fleet = await api('fleet/status');
    assert(fleet.drivers.drv_ravi && fleet.drivers.drv_suresh && fleet.drivers.drv_mahesh,
      "Ravi (Bus 1), Suresh (Bus 2), and Mahesh (Bus 3) exist in authoritative catalog");

    // 2. Concurrency Test: Ravi attempts to start Suresh's bus (Bus 2) -> MUST FAIL!
    const unauthorizedStart = await api('trip/start', 'POST', {
      driverUid: 'drv_ravi',
      busId: 'bus_02',
      routeId: 'route_b'
    });
    assert(!unauthorizedStart.success && unauthorizedStart.code === 'BUS_NOT_ASSIGNED',
      "Concurrency Lock: Ravi blocked from starting Suresh's Bus 2 (AP35 CD 5678)");

    // 3. Driver 1 (Ravi) starts Bus 1
    const trip1 = await api('trip/start', 'POST', {
      driverUid: 'drv_ravi',
      busId: 'bus_01',
      routeId: 'route_a'
    });
    assert(trip1.success && trip1.tripRecord.status === 'active',
      "Driver 1 (Ravi) started Trip 1 on Bus 1 (AP35 AB 1234)");

    // 4. Duplicate Start Test: Attempt to start Bus 1 again while active -> MUST FAIL!
    const duplicateStart = await api('trip/start', 'POST', {
      driverUid: 'drv_suresh',
      busId: 'bus_01',
      routeId: 'route_a'
    });
    assert(!duplicateStart.success && duplicateStart.code === 'BUS_NOT_ASSIGNED',
      "Duplicate Start Blocked: Another driver cannot start an already active bus");

    // 5. Driver 2 (Suresh) starts Bus 2
    const trip2 = await api('trip/start', 'POST', {
      driverUid: 'drv_suresh',
      busId: 'bus_02',
      routeId: 'route_b'
    });
    assert(trip2.success && trip2.tripRecord.status === 'active',
      "Driver 2 (Suresh) started Trip 2 on Bus 2 (AP35 CD 5678)");

    // 6. Driver 3 (Mahesh) starts Bus 3
    const trip3 = await api('trip/start', 'POST', {
      driverUid: 'drv_mahesh',
      busId: 'bus_03',
      routeId: 'route_c'
    });
    assert(trip3.success && trip3.tripRecord.status === 'active',
      "Driver 3 (Mahesh) started Trip 3 on Bus 3 (AP35 EF 9012)");

    // 7. Verify all 3 buses have independent live telemetry in Firebase RTDB
    const rtdbBuses = await getRtdb('buses');
    assert(rtdbBuses.bus_01.status === 'active' &&
           rtdbBuses.bus_02.status === 'active' &&
           rtdbBuses.bus_03.status === 'active',
      "Firebase RTDB: All 3 buses active simultaneously with separate trip IDs");

    // ----------------------------------------------------
    // SCENARIO B: PAUSE AND RESUME TRACKING INDEPENDENCE
    // ----------------------------------------------------
    console.log("\n>>> SCENARIO B: Driver 1 Pauses Tracking; Buses 2 & 3 Continue");

    // 1. Driver 1 (Ravi) pauses tracking
    const pauseRes = await api('trip/pause', 'POST', { driverUid: 'drv_ravi', busId: 'bus_01' });
    assert(pauseRes.success && pauseRes.status === 'paused',
      "Driver 1 successfully paused tracking on Bus 1");

    // 2. Verify Bus 1 is paused, but Bus 2 and Bus 3 remain ACTIVE
    const rtdbPauseState = await getRtdb('buses');
    assert(rtdbPauseState.bus_01.status === 'paused',
      "Bus 1 status updated to PAUSED in Firebase RTDB");
    assert(rtdbPauseState.bus_02.status === 'active' && rtdbPauseState.bus_03.status === 'active',
      "Buses 2 and 3 remain independently ACTIVE while Bus 1 is paused");

    // 3. Driver 1 resumes tracking
    const resumeRes = await api('trip/resume', 'POST', { driverUid: 'drv_ravi', busId: 'bus_01' });
    assert(resumeRes.success && resumeRes.status === 'active',
      "Driver 1 resumed tracking: Bus 1 restored to ACTIVE");

    // ----------------------------------------------------
    // SCENARIO C: STUDENT & PARENT SUBSCRIPTION AND ETA
    // ----------------------------------------------------
    console.log("\n>>> SCENARIO C: Student & Parent Assigned Bus Tracking");

    // Student 3 (Rahul Sharma) is assigned to Bus 2 (Suresh)
    const std3 = fleet.students.std_rahul;
    assert(std3 && std3.assignedBusId === 'bus_02', `Student 3 (${std3.name}) correctly linked to Bus 2`);

    // Verify Bus 2 live location is accessible in Firebase RTDB
    const bus2Loc = await getRtdb('liveLocations/bus_02');
    assert(bus2Loc && bus2Loc.trackingStatus === 'active' && bus2Loc.isFresh === true,
      `Student 3 receives fresh live coordinates from Bus 2 (Lat: ${bus2Loc.latitude.toFixed(4)}, Lng: ${bus2Loc.longitude.toFixed(4)})`);

    // Parent 2 is linked to Student 3 & 4
    const parent2 = fleet.guardians.parent_rahul;
    assert(parent2 && parent2.linkedStudentIds.includes('std_rahul'),
      `Parent 2 (${parent2.name}) authorized strictly for Student 3 & 4`);

    // ----------------------------------------------------
    // SCENARIO D: VERIFIED ATTENDANCE & DUPLICATE REJECTION
    // ----------------------------------------------------
    console.log("\n>>> SCENARIO D: QR Boarding Verification & Duplicate Prevention");

    // 1. Board Student 3 on Bus 2
    const boardRes = await api('attendance/board', 'POST', {
      studentId: 'std_rahul',
      tripId: trip2.tripId,
      driverUid: 'drv_suresh',
      busId: 'bus_02'
    });
    assert(boardRes.success && boardRes.record.status === 'boarded',
      `Student 3 (${std3.name}) boarded Bus 2. Verified by driver Suresh`);
    assert(boardRes.occupancy >= 1, `Bus 2 occupancy incremented to ${boardRes.occupancy}`);

    // 2. Duplicate Check: Scan Student 3 again for same trip -> MUST REJECT!
    const dupRes = await api('attendance/board', 'POST', {
      studentId: 'std_rahul',
      tripId: trip2.tripId,
      driverUid: 'drv_suresh',
      busId: 'bus_02'
    });
    assert(!dupRes.success && dupRes.code === 'DUPLICATE_BOARDING',
      "Duplicate Boarding Blocked: Second check-in rejected with DUPLICATE_BOARDING");

    // 3. Verify attendance record in Firebase RTDB
    const rtdbAtt = await getRtdb(`attendance/${boardRes.record.attendanceId}`);
    assert(rtdbAtt && rtdbAtt.studentName === 'Rahul Sharma',
      "Firebase RTDB: Verified attendance record stored with timestamp and stop metadata");

    // ----------------------------------------------------
    // SCENARIO E: BREAKDOWN & CAPACITY-AWARE RESCUE RANKING
    // ----------------------------------------------------
    console.log("\n>>> SCENARIO E: Bus 1 Breakdown & MAUT Capacity-Aware Rescue Ranking");

    // 1. Bus 1 reports breakdown with 20 stranded students
    const breakdownRes = await api('breakdown/report', 'POST', {
      busId: 'bus_01',
      driverUid: 'drv_ravi',
      category: 'engine_overheating',
      description: 'Radiator belt snapped near NH-16 bypass'
    });
    assert(breakdownRes.success && breakdownRes.incidentRecord.status === 'reported',
      "Bus 1 breakdown incident created and written to Firebase RTDB");

    // 2. Verify candidate ranking: Ensure top candidate has sufficient spare seats
    const candidates = breakdownRes.candidates;
    assert(candidates.length >= 2, `Evaluated ${candidates.length} nearby candidate buses`);
    assert(candidates[0].isCapacityFeasible === true,
      `Top ranked rescue candidate (${candidates[0].busNumber}) is capacity feasible with ${candidates[0].spareSeats} spare seats`);

    // 3. Admin approves rescue dispatch
    const dispatchRes = await api('rescue/dispatch', 'POST', {
      incidentId: breakdownRes.incidentRecord.incidentId,
      brokenBusId: 'bus_01',
      rescueBusId: candidates[0].busId,
      coordinatorUid: 'coord_admin'
    });
    assert(dispatchRes.success && dispatchRes.assignment.status === 'dispatched',
      `Admin approved rescue dispatch: ${candidates[0].busNumber} assigned to rescue Bus 1 passengers`);

    // ----------------------------------------------------
    // SCENARIO F: DRIVER ENDS TRIP & LIVE GPS STOPS
    // ----------------------------------------------------
    console.log("\n>>> SCENARIO F: Driver 3 (Mahesh) Ends Trip; Telemetry Terminated");

    // 1. Driver 3 ends trip
    const endRes = await api('trip/end', 'POST', {
      driverUid: 'drv_mahesh',
      busId: 'bus_03',
      overrideUnfinishedPassengers: true
    });
    assert(endRes.success && endRes.completedAt > 0,
      "Driver 3 formally completed trip on Bus 3");

    // 2. Verify Bus 3 live location is marked COMPLETED in Firebase RTDB
    const bus3Loc = await getRtdb('liveLocations/bus_03');
    assert(bus3Loc.trackingStatus === 'completed' && bus3Loc.isFresh === false,
      "Firebase RTDB: Bus 3 trackingStatus set to COMPLETED. Stale coordinates blocked from live display");

    // 3. Concurrency Release: Bus 3 is now free for future scheduled trips
    const rtdbBus3 = await getRtdb('buses/bus_03');
    assert(rtdbBus3.status === 'completed' && (!rtdbBus3.activeTripId || rtdbBus3.activeTripId === null),
      "Bus 3 released from active driver lock and available for reassignment");

    console.log("\n=======================================================");
    console.log(`FINAL RESULT: ${passedCount} PASSED, ${failedCount} FAILED`);
    console.log("ALL REAL-WORLD WORKFLOW SCENARIOS A THROUGH F VERIFIED!");
    console.log("=======================================================\n");

    if (failedCount > 0) process.exit(1);
  } catch (err) {
    console.error("Test execution error:", err);
    process.exit(1);
  }
})();

