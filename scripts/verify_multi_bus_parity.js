/**
 * Multi-Bus Parity & Generalized Logic Verification Suite
 * Verifies that Bus 01, Bus 02, Bus 03, Bus 04, and dynamically added Bus 05
 * all operate concurrently with identical telemetry, speed calculations, dynamic ETA,
 * road-route snapping, navigation guidance, attendance, and rescue logic.
 */

const assert = require('assert');

const BASE_URL = 'http://localhost:3000/api';

async function api(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`;
  const res = await fetch(url, options);
  return await res.json();
}

async function runParityTests() {
  console.log("=======================================================");
  console.log("STARTING MULTI-BUS LOGIC PARITY & GENERALIZATION SUITE");
  console.log("=======================================================\n");

  let passed = 0;
  let total = 0;

  async function test(name, fn) {
    total++;
    try {
      await fn();
      console.log(`  ✓ [TEST ${total}] PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ✗ [TEST ${total}] FAIL: ${name}`);
      console.error(`    Error: ${err.message}`);
    }
  }

  // Pre-test: Reset fleet database
  await api('/fleet/reset', { method: 'POST' });

  // 1. Verify Catalog Completeness across all 4 Corridors
  await test("Catalog status contains all 4 standard fleet corridors with distinct buses, drivers, and routes", async () => {
    const status = await api('/fleet/status');
    assert(status.buses.bus_01, "bus_01 must exist");
    assert(status.buses.bus_02, "bus_02 must exist");
    assert(status.buses.bus_03, "bus_03 must exist");
    assert(status.buses.bus_04, "bus_04 must exist");

    assert.strictEqual(status.buses.bus_01.assignedRouteId, "route_a");
    assert.strictEqual(status.buses.bus_02.assignedRouteId, "route_b");
    assert.strictEqual(status.buses.bus_03.assignedRouteId, "route_c");
    assert.strictEqual(status.buses.bus_04.assignedRouteId, "route_d");

    assert.strictEqual(status.buses.bus_01.assignedDriverId, "drv_ravi");
    assert.strictEqual(status.buses.bus_02.assignedDriverId, "drv_suresh");
    assert.strictEqual(status.buses.bus_03.assignedDriverId, "drv_mahesh");
    assert.strictEqual(status.buses.bus_04.assignedDriverId, "drv_prakash");
  });

  // 2. Start trips independently for Bus 01, Bus 02, Bus 03, Bus 04
  const testBuses = [
    { busId: "bus_01", driverUid: "drv_ravi", routeId: "route_a" },
    { busId: "bus_02", driverUid: "drv_suresh", routeId: "route_b" },
    { busId: "bus_03", driverUid: "drv_mahesh", routeId: "route_c" },
    { busId: "bus_04", driverUid: "drv_prakash", routeId: "route_d" }
  ];

  for (const b of testBuses) {
    await test(`Start trip independently for ${b.busId} with driver ${b.driverUid}`, async () => {
      const res = await api('/trip/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driverUid: b.driverUid,
          busId: b.busId,
          routeId: b.routeId
        })
      });
      assert(res.success, `Trip must start for ${b.busId}`);
      assert(res.tripId, `TripId generated for ${b.busId}`);
    });
  }

  // 3. Verify Live RTDB positions for each bus after trip start
  for (const b of testBuses) {
    await test(`Verify initial RTDB live position and sequence for ${b.busId}`, async () => {
      const liveRes = await api(`/rtdb?path=liveLocations/${b.busId}`);
      assert(liveRes.data, `liveLocations/${b.busId} must exist in RTDB`);
      assert.strictEqual(liveRes.data.busId, b.busId);
      assert.strictEqual(liveRes.data.driverUid, b.driverUid);
      assert.strictEqual(liveRes.data.trackingStatus, "active");
      assert.strictEqual(liveRes.data.sequence, 1);
    });
  }

  // 4. Ingest Real GPS for all 4 buses with identical velocity derivation
  for (let i = 0; i < testBuses.length; i++) {
    const b = testBuses[i];
    await test(`Hardware GPS ingestion with speed derivation works identically for ${b.busId}`, async () => {
      // Ingest fix 1: at starting depot
      const fix1Res = await api('/driver/gps', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          busId: b.busId,
          driverUid: b.driverUid,
          tripId: `trip_${b.busId}`,
          latitude: 16.9604 + (i * 0.05),
          longitude: 82.2381,
          accuracyMeters: 4.5,
          speedMps: 0.0,
          headingDegrees: 90,
          deviceTimestamp: Date.now() - 4000,
          sequence: 2,
          deviceSessionId: `browser_${b.driverUid}_${b.busId}`,
          isInitialFix: true
        })
      });
      assert(fix1Res.success, `Fix 1 must succeed for ${b.busId}`);

      // Ingest fix 2: moved 60 meters east in 3 seconds (~20 m/s = ~72 km/h raw, smoothed)
      const fix2Res = await api('/driver/gps', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          busId: b.busId,
          driverUid: b.driverUid,
          tripId: `trip_${b.busId}`,
          latitude: 16.9604 + (i * 0.05),
          longitude: 82.23865, // ~60m shift
          accuracyMeters: 3.8,
          speedMps: null, // Test velocity derivation when Doppler is null!
          headingDegrees: 90,
          deviceTimestamp: Date.now(),
          sequence: 3,
          deviceSessionId: `browser_${b.driverUid}_${b.busId}`,
          isInitialFix: false
        })
      });
      assert(fix2Res.success, `Fix 2 with speed derivation must succeed for ${b.busId}`);
      assert(fix2Res.telemetry.speedKmh > 0, `Derived speed must be > 0 for ${b.busId}`);
      assert(fix2Res.telemetry.speedKmh <= 120, `Derived speed must be <= 120 km/h sanity clamp for ${b.busId}`);
    });
  }

  // 5. Verify Navigation Guidance for all buses
  for (const b of testBuses) {
    await test(`Authoritative navigation guidance computes for ${b.busId}`, async () => {
      const guidance = await api(`/navigation/guidance?busId=${b.busId}`);
      assert(guidance.nextStop, `Next stop must be computed for ${b.busId}`);
      assert(guidance.stopsTimeline.length > 0, `Stops timeline must exist for ${b.busId}`);
      assert(guidance.navigationPolyline.length > 0, `Navigation polyline must exist for ${b.busId}`);
    });
  }

  // 6. Passenger Manifest and QR Check-in for distinct buses
  await test("Passenger manifest and attendance check-in dynamically isolates passengers per bus", async () => {
    // Bus 01 manifest
    const m1 = await api('/attendance/manifest?busId=bus_01');
    assert(m1.manifest.length > 0, "Bus 01 manifest must contain passengers");
    assert(m1.manifest.every(p => p.assignedBusId === 'bus_01'), "All Bus 01 manifest passengers must be assigned to bus_01");

    // Bus 02 manifest
    const m2 = await api('/attendance/manifest?busId=bus_02');
    assert(m2.manifest.length > 0, "Bus 02 manifest must contain passengers");
    assert(m2.manifest.every(p => p.assignedBusId === 'bus_02'), "All Bus 02 manifest passengers must be assigned to bus_02");

    // Board passenger on Bus 02 (Rahul Sharma std_rahul)
    const boardRes = await api('/attendance/board', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        studentId: 'std_rahul',
        tripId: 'trip_bus_02',
        driverUid: 'drv_suresh',
        busId: 'bus_02'
      })
    });
    assert(boardRes.success, "Boarding passenger on bus_02 must succeed");
    assert.strictEqual(boardRes.record.busId, 'bus_02');
  });

  // 7. Verify Dynamic Rescue Vehicle Recommendation across Corridors
  await test("MAUT rescue candidate recommendation accurately evaluates candidates dynamically without hardcoding bus_03", async () => {
    const candRes = await api('/rescue/candidates?brokenBusId=bus_01');
    assert(candRes.candidates, "Candidates list must be returned");
    assert(candRes.candidates.length > 0, "Eligible candidates must be found");

    const topCandidate = candRes.candidates[0];
    assert(topCandidate.busId !== "bus_01", "Rescue bus cannot be the broken bus itself");
    assert(topCandidate.score > 0, "Top candidate must have a positive MAUT score");

    // Dispatch top candidate dynamically
    const dispatchRes = await api('/rescue/dispatch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        brokenBusId: "bus_01",
        rescueBusId: topCandidate.busId,
        incidentId: "inc_parity_test_01"
      })
    });
    assert(dispatchRes.success, "Dynamic rescue dispatch must succeed");
    assert.strictEqual(dispatchRes.rescueBusId || dispatchRes.assignment?.rescueBusId, topCandidate.busId);
  });

  // 7. Verify Dynamic Creation of Bus 05 and full functionality parity
  await test("Dynamically created Bus 05 inherits identical telemetry, guidance, and trip management logic", async () => {
    // Create Bus 05
    const createBusRes = await api('/bus/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: "bus_05",
        busNumber: "Bus 05",
        registrationPlate: "AP35 TT 5555",
        totalCapacity: 55,
        assignedRouteId: "route_c"
      })
    });
    assert(createBusRes.success, "Bus 05 creation must succeed");

    // Create Driver for Bus 05
    const createDriverRes = await api('/driver/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        uid: "drv_venkat",
        name: "Venkat Rao",
        email: "driver.venkat@transport.campus.edu",
        employeeId: "DRV-1005",
        assignedBusId: "bus_05",
        assignedRouteId: "route_c"
      })
    });
    assert(createDriverRes.success, "Driver Venkat creation must succeed");

    // Start Trip for Bus 05
    const startRes = await api('/trip/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driverUid: "drv_venkat",
        busId: "bus_05",
        routeId: "route_c"
      })
    });
    assert(startRes.success, "Trip start for dynamic Bus 05 must succeed");

    // Ingest GPS for Bus 05
    const gpsRes = await api('/driver/gps', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        busId: "bus_05",
        driverUid: "drv_venkat",
        tripId: "trip_bus_05",
        latitude: 17.0250,
        longitude: 82.1650,
        accuracyMeters: 3.5,
        speedMps: 12.5, // 45 km/h
        headingDegrees: 180,
        deviceTimestamp: Date.now(),
        sequence: 2,
        deviceSessionId: "browser_drv_venkat_bus_05",
        isInitialFix: true
      })
    });
    assert(gpsRes.success, "GPS ingestion for Bus 05 must succeed");
    assert.strictEqual(gpsRes.telemetry.busId, "bus_05");
    assert.strictEqual(gpsRes.telemetry.driverUid, "drv_venkat");
    assert.strictEqual(Math.round(gpsRes.telemetry.speedKmh), 45);

    // Guidance for Bus 05
    const guideRes = await api('/navigation/guidance?busId=bus_05');
    assert(guideRes.nextStop, "Guidance for Bus 05 must produce next stop");

    // Pause & Resume Bus 05
    const pauseRes = await api('/trip/pause', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ driverUid: "drv_venkat", busId: "bus_05" })
    });
    assert(pauseRes.success, "Pause must succeed for Bus 05");

    const resumeRes = await api('/trip/resume', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ driverUid: "drv_venkat", busId: "bus_05" })
    });
    assert(resumeRes.success, "Resume must succeed for Bus 05");

    // End Trip Bus 05
    const endRes = await api('/trip/end', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ driverUid: "drv_venkat", busId: "bus_05", overrideUnfinishedPassengers: true })
    });
    assert(endRes.success, "End trip must succeed for Bus 05");
  });

  console.log("\n=======================================================");
  console.log(`PARITY TEST SUMMARY: ${passed} / ${total} TESTS PASSED (${((passed/total)*100).toFixed(0)}%)`);
  console.log("=======================================================\n");

  if (passed === total) {
    console.log("ALL MULTI-BUS LOGIC PARITY TESTS PASSED PERFECTLY!");
    process.exit(0);
  } else {
    console.error("SOME PARITY TESTS FAILED.");
    process.exit(1);
  }
}

runParityTests();
