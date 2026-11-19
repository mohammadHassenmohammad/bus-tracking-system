/**
 * Smart Campus Transport - Real-Time Firebase Synchronizer
 * Continuously broadcasts live GPS telemetry, active trips, attendance, and emergency events
 * to https://gps-tracking-b76d8-default-rtdb.firebaseio.com/
 */

const FIREBASE_RTDB_URL = "https://gps-tracking-b76d8-default-rtdb.firebaseio.com";

const COLLEGE_GATE = { lat: 17.0911, lng: 82.0673, name: "Aditya University Main Gate" };

// Complete Fleet Definition
const BUSES = {
  bus_01: {
    id: "bus_01",
    number: "Bus 12 (Express)",
    plate: "AP-05-TJ-1012",
    driver: "M. S. Prasad",
    driverPhone: "+91 98765 43212",
    routeId: "route_01",
    routeName: "Kakinada City Express",
    status: "moving",
    totalCapacity: 52,
    occupiedSeats: 38,
    fuelLevel: 85,
    speed: 36.5,
    heading: 315.0,
    accuracy: 4.2
  },
  bus_02: {
    id: "bus_02",
    number: "Bus 07",
    plate: "AP-05-TJ-1007",
    driver: "K. Rambabu",
    driverPhone: "+91 98765 43215",
    routeId: "route_02",
    routeName: "Rajahmundry Direct Line",
    status: "moving",
    totalCapacity: 50,
    occupiedSeats: 24,
    fuelLevel: 78,
    speed: 42.0,
    heading: 65.0,
    accuracy: 5.0
  },
  bus_03: {
    id: "bus_03",
    number: "Bus 24 (Shuttle)",
    plate: "AP-05-TJ-1024",
    driver: "N. Satyanarayana",
    driverPhone: "+91 98765 43216",
    routeId: "route_03",
    routeName: "Samalkot Railway Junction",
    status: "stationary",
    totalCapacity: 45,
    occupiedSeats: 41,
    fuelLevel: 92,
    speed: 0.0,
    heading: 280.0,
    accuracy: 3.8
  },
  bus_04: {
    id: "bus_04",
    number: "Bus 18",
    plate: "AP-05-TJ-1018",
    driver: "P. Venkat Rao",
    driverPhone: "+91 98765 43217",
    routeId: "route_04",
    routeName: "Peddapuram Shuttle",
    status: "moving",
    totalCapacity: 48,
    occupiedSeats: 25,
    fuelLevel: 80,
    speed: 31.0,
    heading: 250.0,
    accuracy: 4.5
  },
  bus_05: {
    id: "bus_05",
    number: "Bus 31 (Rural)",
    plate: "AP-05-TJ-1031",
    driver: "G. Appa Rao",
    driverPhone: "+91 98765 43218",
    routeId: "route_05",
    routeName: "Annavaram Rural Route",
    status: "breakdown",
    totalCapacity: 50,
    occupiedSeats: 27,
    fuelLevel: 65,
    speed: 0.0,
    heading: 215.0,
    accuracy: 6.0
  }
};

// Route Waypoints for realistic road progression
const ROUTE_WAYPOINTS = {
  route_01: [
    { lat: 16.9604, lng: 82.2381 },
    { lat: 16.9720, lng: 82.2310 },
    { lat: 16.9850, lng: 82.2220 },
    { lat: 17.0010, lng: 82.2030 },
    { lat: 17.0180, lng: 82.1850 },
    { lat: 17.0350, lng: 82.1620 },
    { lat: 17.0520, lng: 82.1380 },
    { lat: 17.0710, lng: 82.1020 },
    { lat: 17.0850, lng: 82.0800 },
    COLLEGE_GATE
  ],
  route_02: [
    { lat: 17.0005, lng: 81.7770 },
    { lat: 17.0150, lng: 81.8020 },
    { lat: 17.0450, lng: 81.8500 },
    { lat: 17.0820, lng: 81.9050 },
    COLLEGE_GATE
  ],
  route_03: [
    { lat: 17.0515, lng: 82.1680 },
    { lat: 17.0580, lng: 82.1520 },
    { lat: 17.0720, lng: 82.1100 },
    COLLEGE_GATE
  ],
  route_04: [
    { lat: 17.0780, lng: 82.1350 },
    { lat: 17.0840, lng: 82.1050 },
    COLLEGE_GATE
  ],
  route_05: [
    { lat: 17.2800, lng: 82.4050 },
    { lat: 17.2400, lng: 82.3400 },
    { lat: 17.1850, lng: 82.2150 },
    COLLEGE_GATE
  ]
};

const busWaypointIndices = {
  bus_01: 3,
  bus_02: 1,
  bus_03: 1,
  bus_04: 1,
  bus_05: 2
};

async function putData(path, data) {
  try {
    const res = await fetch(`${FIREBASE_RTDB_URL}/${path}.json`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  } catch (err) {
    console.error(`[Firebase Write Error at ${path}]:`, err.message);
  }
}

async function seedInitialDatabase() {
  console.log("\n=======================================================");
  console.log("SEEDING REAL-TIME FIREBASE DATABASE");
  console.log(`Target: ${FIREBASE_RTDB_URL}`);
  console.log("=======================================================\n");

  // 1. Seed Buses Profile
  console.log("1. Writing active bus fleet catalog...");
  await putData('buses', BUSES);

  // 2. Seed Route Catalog
  console.log("2. Writing institutional route geometries...");
  await putData('routes', {
    route_01: {
      id: "route_01",
      code: "R-01",
      name: "Kakinada City Express",
      distanceKm: 28.5,
      estimatedMinutes: 45,
      stops: [
        { name: "Bhanugudi Junction", lat: 16.9604, lng: 82.2381, pickup: "07:15 AM", students: 8 },
        { name: "Main Road Cinema Hall", lat: 16.9850, lng: 82.2220, pickup: "07:25 AM", students: 12 },
        { name: "Madhavapatnam Bypass", lat: 17.0180, lng: 82.1850, pickup: "07:38 AM", students: 9 },
        { name: "Samalkot Flyover", lat: 17.0520, lng: 82.1380, pickup: "07:48 AM", students: 11 },
        { name: "Aditya Campus Gate", lat: 17.0911, lng: 82.0673, pickup: "08:05 AM", students: 0 }
      ]
    },
    route_02: {
      id: "route_02",
      code: "R-02",
      name: "Rajahmundry Direct Line",
      distanceKm: 34.2,
      estimatedMinutes: 52
    },
    route_03: {
      id: "route_03",
      code: "R-03",
      name: "Samalkot Railway Junction",
      distanceKm: 14.8,
      estimatedMinutes: 28
    },
    route_04: {
      id: "route_04",
      code: "R-04",
      name: "Peddapuram Shuttle",
      distanceKm: 11.2,
      estimatedMinutes: 22
    },
    route_05: {
      id: "route_05",
      code: "R-05",
      name: "Annavaram Rural Route",
      distanceKm: 38.6,
      estimatedMinutes: 55
    }
  });

  // 3. Seed Initial Breakdown Incident
  console.log("3. Writing active breakdown & emergency alerts...");
  await putData('activeIncidents', {
    inc_001: {
      id: "inc_001",
      busId: "bus_05",
      busNumber: "Bus 31 (Rural)",
      driver: "G. Appa Rao",
      category: "breakdown",
      severity: "high",
      status: "reported",
      lat: 17.1850,
      lng: 82.2150,
      description: "Engine radiator leak near Prathipadu NH-16",
      passengerCount: 27,
      reportedAt: Date.now() - 360000
    }
  });

  // 4. Seed Verified Attendance Records
  console.log("4. Writing verified student attendance records...");
  await putData('attendance', {
    att_001: {
      id: "att_001",
      studentId: "student_001",
      studentName: "Aditya Varma",
      rollNumber: "21A91A0501",
      busId: "bus_01",
      stopName: "Madhavapatnam Bypass",
      status: "boarded",
      timestamp: Date.now() - 1800000,
      verifiedBy: "driver_b1",
      method: "qr_code"
    }
  });

  // 5. Seed Announcements
  console.log("5. Writing transport announcements & notices...");
  await putData('announcements', {
    ann_01: {
      id: "ann_01",
      title: "Mid-Term Examinations: Special Bus Timings",
      content: "Morning bus departure from all terminal points will commence 20 minutes earlier (06:55 AM) from Nov 20 to Nov 25.",
      isUrgent: true,
      createdAt: Date.now() - 7200000
    },
    ann_02: {
      id: "ann_02",
      title: "Route 01 Canal Bridge Maintenance",
      content: "Bus 12 will detour via Madhavapatnam bypass road. Students board at the flyover.",
      isUrgent: false,
      createdAt: Date.now() - 86400000
    }
  });

  console.log("\nDatabase seeded successfully! Starting real-time GPS streaming loop...\n");
}

// 3-Second Real-Time Telemetry Streaming Loop
function startRealtimeGpsStream() {
  setInterval(async () => {
    const liveLocations = {};
    const now = Date.now();

    for (const busId in BUSES) {
      const bus = BUSES[busId];
      const waypoints = ROUTE_WAYPOINTS[bus.routeId] || ROUTE_WAYPOINTS.route_01;

      if (bus.status === 'moving') {
        let idx = busWaypointIndices[busId];
        idx = (idx + 1) % waypoints.length;
        busWaypointIndices[busId] = idx;

        const target = waypoints[idx];
        const jitterLat = (Math.random() - 0.5) * 0.0003;
        const jitterLng = (Math.random() - 0.5) * 0.0003;

        bus.lat = target.lat + jitterLat;
        bus.lng = target.lng + jitterLng;
        bus.speed = Math.floor(30 + Math.random() * 15);
        bus.heading = (idx * 40) % 360;
      } else {
        // Stationary or breakdown position
        const target = waypoints[busWaypointIndices[busId]];
        bus.lat = target.lat;
        bus.lng = target.lng;
        bus.speed = 0.0;
      }

      liveLocations[busId] = {
        busId: bus.id,
        number: bus.number,
        driver: bus.driver,
        routeId: bus.routeId,
        latitude: bus.lat,
        longitude: bus.lng,
        speedKmh: bus.speed,
        heading: bus.heading,
        accuracyMeters: bus.accuracy,
        status: bus.status,
        occupiedSeats: bus.occupiedSeats,
        totalCapacity: bus.totalCapacity,
        timestamp: now,
        isFresh: true
      };
    }

    // Push real-time coordinates to Firebase RTDB
    await putData('liveLocations', liveLocations);

    // Update system summary stats
    await putData('systemStats', {
      totalFleet: Object.keys(BUSES).length,
      movingCount: Object.values(BUSES).filter(b => b.status === 'moving').length,
      delayedCount: Object.values(BUSES).filter(b => b.status === 'delayed').length,
      breakdownCount: Object.values(BUSES).filter(b => b.status === 'breakdown').length,
      totalStudentsBoarded: 163,
      lastTelemetryPing: now,
      serverStatus: "ONLINE_STREAMING"
    });

    process.stdout.write(`\r[Firebase RTDB Live Stream] Synced 5 vehicles at ${new Date(now).toLocaleTimeString()} | Target: ${FIREBASE_RTDB_URL}`);
  }, 3000);
}

// Execution entry point
(async () => {
  await seedInitialDatabase();
  startRealtimeGpsStream();
})();

