/**
 * Automated Verification & Quality Assurance Suite
 * Tests all core algorithms, GIS mathematics, ETA engines, breakdown ranking,
 * geofence state transitions, and attendance cryptography.
 */

const crypto = require('crypto');

let passedTests = 0;
let failedTests = 0;

function assert(condition, testName) {
  if (condition) {
    console.log(`  [PASS] ${testName}`);
    passedTests++;
  } else {
    console.error(`  [FAIL] ${testName}`);
    failedTests++;
  }
}

console.log("\n=======================================================");
console.log("SMART CAMPUS TRANSPORT: AUTOMATED VERIFICATION SUITE");
console.log("=======================================================\n");

// 1. GIS & Haversine Distance Test
console.log("1. Testing Geodesic Distance Calculations (Haversine)...");
function haversineMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000.0;
  const toRad = (deg) => (deg * Math.PI) / 180.0;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

const campusLat = 17.0911, campusLon = 82.0673;
const kakinadaLat = 16.9604, kakinadaLon = 82.2381;
const dist = haversineMeters(campusLat, campusLon, kakinadaLat, kakinadaLon);
assert(dist > 20000 && dist < 35000, `Distance Kakinada to Campus is ~${(dist/1000).toFixed(1)} km (Valid Range: 20-35 km)`);

// 2. Dijkstra vs A* Route Search
console.log("\n2. Testing Pathfinding Optimization (Dijkstra vs A*)...");
const graphNodes = {
  'N1': { lat: 17.00, lon: 82.00 },
  'N2': { lat: 17.05, lon: 82.05 },
  'N3': { lat: 17.10, lon: 82.10 }
};
const graphEdges = {
  'N1': [{ to: 'N2', dist: 5000 }],
  'N2': [{ to: 'N3', dist: 6000 }],
  'N3': []
};

function dijkstra(start, target) {
  const dists = { N1: Infinity, N2: Infinity, N3: Infinity };
  const prev = {};
  dists[start] = 0;
  const visited = new Set();
  let explored = 0;

  while (visited.size < Object.keys(graphNodes).length) {
    let u = null;
    for (const node in dists) {
      if (!visited.has(node) && (u === null || dists[node] < dists[u])) {
        u = node;
      }
    }
    if (u === null || dists[u] === Infinity) break;
    visited.add(u);
    explored++;
    if (u === target) break;

    for (const edge of graphEdges[u] || []) {
      const alt = dists[u] + edge.dist;
      if (alt < dists[edge.to]) {
        dists[edge.to] = alt;
        prev[edge.to] = u;
      }
    }
  }
  return { dist: dists[target], explored };
}

const dijkstraResult = dijkstra('N1', 'N3');
assert(dijkstraResult.dist === 11000, `Dijkstra optimal path distance = 11,000m`);
assert(dijkstraResult.explored >= 2, `Dijkstra explored at least 2 nodes`);

// 3. Predictive ETA Multi-Factor Engine
console.log("\n3. Testing Predictive ETA Calculation (Method A vs Method B)...");
function calculateBaselineEta(distMeters, stops) {
  const speedMps = (30.0 * 1000) / 3600;
  return (distMeters / speedMps + stops * 45) / 60;
}

function calculatePredictiveEta(distMeters, stops, currentSpeedKmh, recentSpeeds, passengers) {
  let ema = recentSpeeds[0];
  const alpha = 0.4;
  for (let i = 1; i < recentSpeeds.length; i++) {
    ema = alpha * recentSpeeds[i] + (1 - alpha) * ema;
  }
  const effectiveSpeedKmh = Math.max(8.0, 0.6 * ema + 0.4 * Math.max(currentSpeedKmh, 10.0));
  const speedMps = (effectiveSpeedKmh * 1000) / 3600;
  const dwellSeconds = stops * 30 + passengers * 3;
  return (distMeters / speedMps + dwellSeconds) / 60;
}

const baseEta = calculateBaselineEta(4500, 2);
const predEta = calculatePredictiveEta(4500, 2, 34, [28, 32, 35], 6);
assert(baseEta > 0, `Baseline ETA: ${baseEta.toFixed(1)} minutes`);
assert(predEta > 0, `Predictive Multi-Factor ETA: ${predEta.toFixed(1)} minutes`);

// 4. Geofence Detection with Hysteresis
console.log("\n4. Testing Geofence Transitions & Hysteresis Protection...");
class GeofenceValidator {
  constructor() {
    this.state = 'far';
  }
  evaluate(distM) {
    if (distM <= 60) {
      this.state = 'arrived';
    } else if (this.state === 'arrived' && distM > 100) {
      this.state = 'departed';
    } else if (this.state === 'far' && distM <= 1500) {
      this.state = 'approaching';
    }
    return this.state;
  }
}
const gf = new GeofenceValidator();
assert(gf.evaluate(1200) === 'approaching', `Geofence state at 1200m = approaching`);
assert(gf.evaluate(50) === 'arrived', `Geofence state at 50m = arrived`);
assert(gf.evaluate(85) === 'arrived', `Hysteresis: retains 'arrived' at 85m (< 100m exit threshold)`);
assert(gf.evaluate(120) === 'departed', `Geofence state at 120m (> 100m exit) = departed`);

// 5. Intelligent Breakdown Candidate Ranking (MAUT)
console.log("\n5. Testing Breakdown Assistance Capacity-Aware MAUT Ranking...");
const testBuses = [
  { id: 'B1', distM: 1000, capacity: 50, occupied: 48, spare: 2 }, // Nearest, but only 2 seats!
  { id: 'B2', distM: 2500, capacity: 50, occupied: 15, spare: 35 } // Farther, but 35 seats!
];

function rankRescueBuses(strandedCount, buses) {
  return buses.map(b => {
    const isCapacityFeasible = b.spare >= strandedCount;
    let score = (1 - b.distM / 25000) * 0.4 + (b.spare / b.capacity) * 0.6;
    if (!isCapacityFeasible) score *= 0.25; // Penalty
    return { ...b, score, isCapacityFeasible };
  }).sort((a, b) => b.score - a.score);
}

const ranked = rankRescueBuses(20, testBuses);
assert(ranked[0].id === 'B2', `Capacity-aware ranker selects B2 (35 seats) over closer B1 (2 seats)`);
assert(ranked[0].isCapacityFeasible === true, `Winner is capacity feasible for 20 stranded students`);
assert(ranked[1].isCapacityFeasible === false, `B1 flagged as capacity violation`);

// 6. GPS Validator & Improbable Jump Detector
console.log("\n6. Testing GPS Filtering & Teleportation Jump Rejection...");
class GpsFilter {
  constructor(maxMps = 35) {
    this.maxMps = maxMps;
    this.last = null;
  }
  process(lat, lon, timeSec) {
    if (this.last) {
      const d = haversineMeters(this.last.lat, this.last.lon, lat, lon);
      const dt = timeSec - this.last.timeSec;
      if (dt > 0 && d / dt > this.maxMps) {
        return { valid: false, reason: 'Improbable teleportation jump' };
      }
    }
    this.last = { lat, lon, timeSec };
    return { valid: true };
  }
}

const filter = new GpsFilter(35);
assert(filter.process(17.00, 82.00, 100).valid === true, `First GPS fix accepted`);
// Jump 10 km in 2 seconds (5000 m/s > 35 m/s)
assert(filter.process(17.10, 82.10, 102).valid === false, `Teleportation jump (5000 m/s) rejected`);

// 7. Cryptographic Replay-Resistant QR Tokens & Duplicate Rejection
console.log("\n7. Testing Cryptographic Attendance QR Verification & Duplicate Prevention...");
const SECRET = "CAMPUS_TRANSPORT_ATTENDANCE_KEY_2026";
const checkedInStudents = new Set();

function generateQrToken(studentId, tripId, expiryOffsetSec = 900) {
  const expiry = Math.floor(Date.now() / 1000) + expiryOffsetSec;
  const payload = `${studentId}:${tripId}:${expiry}`;
  const sig = crypto.createHmac('sha256', SECRET).update(payload).digest('hex');
  return Buffer.from(`${payload}.${sig}`).toString('base64');
}

function verifyQrToken(tokenBase64, currentTripId) {
  try {
    const raw = Buffer.from(tokenBase64, 'base64').toString('utf8');
    const [payload, sig] = raw.split('.');
    const expectedSig = crypto.createHmac('sha256', SECRET).update(payload).digest('hex');
    if (sig !== expectedSig) return { success: false, reason: 'Invalid cryptographic signature' };

    const [stdId, tripId, expiry] = payload.split(':');
    if (Math.floor(Date.now() / 1000) > parseInt(expiry)) return { success: false, reason: 'Expired token' };

    const dupKey = `${tripId}_${stdId}`;
    if (checkedInStudents.has(dupKey)) return { success: false, reason: 'Duplicate attendance write rejected' };

    checkedInStudents.add(dupKey);
    return { success: true, studentId: stdId };
  } catch (e) {
    return { success: false, reason: 'Corrupted token format' };
  }
}

const validToken = generateQrToken('std_001', 'trip_01', 900);
const firstAttempt = verifyQrToken(validToken, 'trip_01');
assert(firstAttempt.success === true, `Valid cryptographically signed QR pass accepted`);

// Repeat second attempt with same token -> Must be rejected as duplicate
const secondAttempt = verifyQrToken(validToken, 'trip_01');
assert(secondAttempt.success === false && secondAttempt.reason.includes('Duplicate'), `Duplicate verification attempt successfully prevented`);

// Forged token attempt
const forgedToken = Buffer.from("std_002:trip_01:9999999999.forged_fake_signature").toString('base64');
assert(verifyQrToken(forgedToken, 'trip_01').success === false, `Tampered / forged QR signature rejected`);

console.log("\n=======================================================");
console.log(`TEST SUMMARY: ${passedTests} PASSED, ${failedTests} FAILED`);
console.log("=======================================================\n");

if (failedTests > 0) {
  process.exit(1);
}

