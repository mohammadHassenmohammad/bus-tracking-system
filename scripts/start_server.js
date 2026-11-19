const http = require('http');
const fs = require('fs');
const path = require('path');
const engine = require('./backend_telemetry_engine');

const PORT = 3000;
const WEB_DIR = path.join(__dirname, '..', 'web');

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.csv': 'text/csv'
};

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (err) {
        reject(err);
      }
    });
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    return res.end();
  }

  const [reqPath] = req.url.split('?');

  if (reqPath.startsWith('/api/')) {
    try {
      // 1. Real GPS ingestion from Driver device
      if (reqPath === '/api/driver/gps' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.ingestRealGpsCoordinate(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // 2. Admin creates driver account
      if (reqPath === '/api/driver/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const { name, employeeId, mobile, email, licenseNumber, assignedBusId, assignedRouteId } = body;
        if (!name || !employeeId || !email || !assignedBusId) {
          return sendJson(res, 400, { success: false, error: "Missing required driver fields." });
        }

        const driverUid = body.uid || body.driverUid || `drv_${employeeId.toLowerCase().replace(/[^a-z0-9]/g, '')}`;
        const newDriver = {
          uid: driverUid,
          name,
          employeeId,
          mobile: mobile || "",
          email,
          licenseNumber: licenseNumber || "N/A",
          assignedBusId,
          assignedRouteId: assignedRouteId || (assignedBusId && engine.FLEET_DATA.buses[assignedBusId]?.assignedRouteId) || Object.keys(engine.FLEET_DATA.routes)[0],
          isEnabled: true,
          activationStatus: "activated"
        };

        engine.FLEET_DATA.drivers[driverUid] = newDriver;
        if (engine.FLEET_DATA.buses[assignedBusId]) {
          engine.FLEET_DATA.buses[assignedBusId].assignedDriverId = driverUid;
        }

        await engine.rtdbPut(`drivers/${driverUid}`, newDriver);
        await engine.rtdbPatch(`buses/${assignedBusId}`, { assignedDriverId: driverUid });

        return sendJson(res, 201, { success: true, driver: newDriver });
      }

      // 3. Admin toggles driver status
      if (reqPath === '/api/driver/status' && req.method === 'PATCH') {
        const body = await parseJsonBody(req);
        const { driverUid, isEnabled } = body;
        if (engine.FLEET_DATA.drivers[driverUid]) {
          engine.FLEET_DATA.drivers[driverUid].isEnabled = !!isEnabled;
          await engine.rtdbPatch(`drivers/${driverUid}`, { isEnabled: !!isEnabled });
          return sendJson(res, 200, { success: true, driverUid, isEnabled: !!isEnabled });
        }
        return sendJson(res, 404, { error: "Driver not found" });
      }

      // 4. Trip controls (Start, Pause, Resume, End)
      if (reqPath === '/api/trip/start' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.startTrip(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath === '/api/trip/pause' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.pauseTrip(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath === '/api/trip/resume' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.resumeTrip(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath === '/api/trip/end' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.endTrip(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // 5. Boarding & Exit Verification
      if (reqPath === '/api/attendance/board' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.verifyBoarding(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath === '/api/attendance/exit' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.verifyExit(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // 6. Breakdown & Rescue
      if (reqPath === '/api/breakdown/report' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.reportBreakdown(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath.startsWith('/api/rescue/candidates') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const brokenBusId = urlParams.searchParams.get('brokenBusId') || Object.keys(engine.FLEET_DATA.buses)[0];
        const candidates = engine.getCandidateRescueBuses ? engine.getCandidateRescueBuses(brokenBusId) : [];
        return sendJson(res, 200, { success: true, brokenBusId, candidates });
      }
      if (reqPath === '/api/rescue/dispatch' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.dispatchRescue(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // Navigation Guidance API for Driver
      if (reqPath.startsWith('/api/navigation/guidance') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const busId = urlParams.searchParams.get('busId') || Object.keys(engine.FLEET_DATA.buses)[0];
        const bus = engine.FLEET_DATA.buses[busId];
        if (!bus) return sendJson(res, 404, { error: "Bus not found" });

        const liveLoc = (await engine.rtdbGet(`liveLocations/${busId}`)) || engine.busTelemetry?.[busId];
        const lat = parseFloat(urlParams.searchParams.get('lat')) || (liveLoc ? liveLoc.latitude : 16.9604);
        const lng = parseFloat(urlParams.searchParams.get('lng')) || (liveLoc ? liveLoc.longitude : 82.2381);
        const speedKmh = parseFloat(urlParams.searchParams.get('speedKmh')) || (liveLoc ? liveLoc.speedKmh : 0);
        const heading = parseFloat(urlParams.searchParams.get('heading')) || (liveLoc ? liveLoc.headingDegrees : 0);

        const guidance = engine.calculateNavigationGuidance({
          busId,
          latitude: lat,
          longitude: lng,
          speedKmh,
          headingDegrees: heading
        });

        return sendJson(res, 200, guidance);
      }

      // Advance Stop API (Driver or Geofence confirmed stop departure)
      if (reqPath === '/api/trip/advance-stop' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.advanceStop(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // 7. Student Automatic Live Subscription API
      if (reqPath.startsWith('/api/student/live') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const studentId = urlParams.searchParams.get('studentId') || 'std_anil';
        const student = engine.FLEET_DATA.students[studentId];

        if (!student) return sendJson(res, 404, { error: "Student not found" });

        const bus = engine.FLEET_DATA.buses[student.assignedBusId];
        const route = engine.FLEET_DATA.routes[student.assignedRouteId];
        const stop = route?.stops.find(s => s.id === student.assignedStopId);

        const liveLoc = (await engine.rtdbGet(`liveLocations/${student.assignedBusId}`)) || engine.busTelemetry?.[student.assignedBusId];
        const isTripActive = bus && bus.status === 'active';
        const isPaused = bus && bus.status === 'paused';
        const isCompleted = bus && bus.status === 'completed';

        let distanceMeters = 0;
        let etaMinutes = 0;
        let trackingQuality = "Unavailable";
        let guidance = null;

        if (liveLoc && isTripActive) {
          distanceMeters = engine.calculateRoadRouteDistance(
            liveLoc.latitude,
            liveLoc.longitude,
            stop ? stop.lat : 17.02,
            stop ? stop.lng : 82.18,
            route ? route.waypoints : []
          );
          etaMinutes = engine.calculatePredictiveEtaMinutes(distanceMeters, 1, liveLoc.speedKmh);
          trackingQuality = liveLoc.accuracyClassification || "Good";

          guidance = engine.calculateNavigationGuidance({
            busId: student.assignedBusId,
            latitude: liveLoc.latitude,
            longitude: liveLoc.longitude,
            speedKmh: liveLoc.speedKmh,
            headingDegrees: liveLoc.headingDegrees
          });
        }

        return sendJson(res, 200, {
          student,
          bus: {
            id: bus?.id,
            busNumber: bus?.busNumber,
            registrationPlate: bus?.registrationPlate,
            status: bus?.status,
            occupiedSeats: bus?.occupiedSeats,
            totalCapacity: bus?.totalCapacity,
            assignedDriverName: (bus?.assignedDriverId && engine.FLEET_DATA.drivers[bus.assignedDriverId]?.name) || "Assigned Driver"
          },
          route: {
            id: route?.id,
            name: route?.name,
            stops: route?.stops,
            waypoints: route?.waypoints
          },
          stop,
          tripStatus: bus ? bus.status : 'scheduled',
          isTripActive,
          isPaused,
          isCompleted,
          liveCoordinates: liveLoc ? { lat: liveLoc.latitude, lng: liveLoc.longitude } : null,
          headingDegrees: liveLoc ? (liveLoc.headingDegrees || 0) : 0,
          speedKmh: liveLoc ? liveLoc.speedKmh : 0,
          roadDistanceKm: parseFloat((distanceMeters / 1000.0).toFixed(1)),
          predictiveEtaMinutes: etaMinutes,
          trackingQuality,
          lastUpdatedAgoSeconds: liveLoc ? Math.floor((Date.now() - liveLoc.serverReceivedAt) / 1000) : null,
          nextStop: guidance ? guidance.nextStop : null,
          stopsTimeline: guidance ? guidance.stopsTimeline : (route?.stops.map((s, idx) => ({ ...s, status: idx === 0 ? 'current' : 'upcoming' })) || []),
          completedPolyline: guidance ? guidance.completedPolyline : [],
          remainingPolyline: guidance ? guidance.navigationPolyline : (route?.waypoints || []),
          isOffRoute: guidance ? guidance.isOffRoute : false
        });
      }

      // 8. Authoritative Catalog Status & Reset
      if (reqPath === '/api/fleet/status' && req.method === 'GET') {
        return sendJson(res, 200, {
          buses: engine.FLEET_DATA.buses,
          drivers: engine.FLEET_DATA.drivers,
          routes: engine.FLEET_DATA.routes,
          students: engine.FLEET_DATA.students,
          guardians: engine.FLEET_DATA.guardians,
          announcements: engine.FLEET_DATA.announcements
        });
      }
      if (reqPath === '/api/fleet/reset' && req.method === 'POST') {
        engine.resetFleetData();
        await engine.initializeAuthoritativeDatabase();
        return sendJson(res, 200, { success: true, message: "Fleet database and memory state reset to initial catalog." });
      }

      // 9. Administrative Entity Endpoints
      // A. Driver assignment & deletion
      if (reqPath === '/api/driver/assign' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.assignDriver(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if ((reqPath === '/api/driver/delete' && req.method === 'POST') || (reqPath === '/api/driver' && req.method === 'DELETE')) {
        const body = await parseJsonBody(req);
        const result = await engine.deleteDriver(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // B. Bus Fleet CRUD
      if (reqPath === '/api/bus/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.createBus(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }
      if (reqPath === '/api/bus/update' && (req.method === 'PATCH' || req.method === 'POST')) {
        const body = await parseJsonBody(req);
        const result = await engine.updateBus(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if ((reqPath === '/api/bus/delete' && req.method === 'POST') || (reqPath === '/api/bus' && req.method === 'DELETE')) {
        const body = await parseJsonBody(req);
        const result = await engine.deleteBus(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // C. Routes & Stops CRUD
      if (reqPath === '/api/route/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.createRoute(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }
      if (reqPath === '/api/stop/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.addStopToRoute(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }
      if (reqPath === '/api/stop/delete' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.deleteStop(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // D. Students & Parents CRUD
      if (reqPath === '/api/student/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.createStudent(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }
      if (reqPath === '/api/student/assign' && (req.method === 'PATCH' || req.method === 'POST')) {
        const body = await parseJsonBody(req);
        const result = await engine.assignStudent(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if ((reqPath === '/api/student/delete' && req.method === 'POST') || (reqPath === '/api/student' && req.method === 'DELETE')) {
        const body = await parseJsonBody(req);
        const result = await engine.deleteStudent(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }
      if (reqPath === '/api/parent/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.createParent(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }

      // E. Announcements & Broadcast Notifications
      if (reqPath === '/api/announcements' && req.method === 'GET') {
        return sendJson(res, 200, { success: true, announcements: engine.FLEET_DATA.announcements });
      }
      if (reqPath === '/api/announcements/create' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.createAnnouncement(body);
        return sendJson(res, result.success ? 201 : 400, result);
      }
      if (reqPath === '/api/announcements/delete' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.deleteAnnouncement(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // F. Passenger Manifest & Manual Check-in
      if (reqPath.startsWith('/api/attendance/manifest') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const busId = urlParams.searchParams.get('busId') || Object.keys(engine.FLEET_DATA.buses)[0];
        const manifest = engine.getPassengerManifest(busId);
        return sendJson(res, 200, { success: true, busId, manifest });
      }
      if (reqPath === '/api/attendance/manual-checkin' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const result = await engine.manualCheckIn(body);
        return sendJson(res, result.success ? 200 : 400, result);
      }

      // G. Missed Bus Assistant / Alternative Buses
      if (reqPath.startsWith('/api/routes/alternatives') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const studentId = urlParams.searchParams.get('studentId') || Object.keys(engine.FLEET_DATA.students)[0];
        const stopId = urlParams.searchParams.get('stopId');
        const result = engine.findAlternativeBuses({ studentId, currentStopId: stopId });
        return sendJson(res, 200, result);
      }

      // H. Fleet Analytics & Performance KPIs
      if (reqPath === '/api/analytics/kpis' && req.method === 'GET') {
        const kpis = engine.getFleetAnalytics();
        return sendJson(res, 200, { success: true, kpis });
      }

      // I. Audit Trail & System Logs
      if (reqPath === '/api/system/audit-logs' && req.method === 'GET') {
        return sendJson(res, 200, { success: true, logs: engine.SYSTEM_AUDIT_LOGS });
      }

      // J. CSV Exports (Attendance & Trips)
      if (reqPath === '/api/attendance/export-csv' && req.method === 'GET') {
        const csv = engine.exportAttendanceCsv();
        res.writeHead(200, {
          'Content-Type': 'text/csv',
          'Content-Disposition': 'attachment; filename="smart_campus_attendance_log.csv"',
          'Access-Control-Allow-Origin': '*'
        });
        return res.end(csv);
      }

      // K. Auth Login with Strict Role Verification
      if (reqPath === '/api/auth/login' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const { email, password, expectedRole } = body;
        const cleanEmail = (email || '').trim().toLowerCase();

        let account = null;
        let role = null;

        // 1. Match Guardians / Parents
        for (const [uid, grd] of Object.entries(engine.FLEET_DATA.guardians)) {
          if (grd.email && grd.email.toLowerCase() === cleanEmail) {
            account = { ...grd, role: 'guardian', isEnabled: true };
            role = 'guardian';
            break;
          }
        }
        // 2. Match Drivers
        if (!account) {
          for (const [uid, drv] of Object.entries(engine.FLEET_DATA.drivers)) {
            if (drv.email && drv.email.toLowerCase() === cleanEmail) {
              account = { ...drv, role: 'driver' };
              role = 'driver';
              break;
            }
          }
        }
        // 3. Match Students
        if (!account) {
          for (const [uid, std] of Object.entries(engine.FLEET_DATA.students)) {
            const stdEmail = (std.email || `${std.name.toLowerCase().replace(/[^a-z]/g, '')}.student@campus.edu`).toLowerCase();
            const idEmail = `${std.id.replace('std_', '')}.student@campus.edu`;
            if (stdEmail === cleanEmail || idEmail === cleanEmail || cleanEmail.startsWith(std.id.replace('std_', '') + '@') || cleanEmail.startsWith(std.id.replace('std_', '') + '.')) {
              if (cleanEmail.includes('parent')) continue; // Guard against parent prefix
              account = { ...std, email: stdEmail, role: 'student', isEnabled: true };
              role = 'student';
              break;
            }
          }
        }
        // 4. Match Admins
        if (!account && (cleanEmail === 'admin@campus.edu' || cleanEmail === 'controlroom@campus.edu')) {
          account = { uid: 'admin_001', name: 'Campus Admin', email: cleanEmail, role: 'admin', isEnabled: true };
          role = 'admin';
        }

        if (!account) {
          return sendJson(res, 404, { success: false, code: 'USER_NOT_FOUND', error: 'No registered transportation account found.' });
        }
        if (password !== 'password123' && password !== 'admin123') {
          return sendJson(res, 401, { success: false, code: 'WRONG_PASSWORD', error: 'Invalid password.' });
        }
        if (account.isEnabled === false) {
          return sendJson(res, 403, { success: false, code: 'ACCOUNT_DISABLED', error: 'Your account has been deactivated.' });
        }
        if (expectedRole && expectedRole !== role) {
          return sendJson(res, 403, {
            success: false,
            code: 'ROLE_MISMATCH',
            error: `Access Denied: You are attempting to log into the ${expectedRole.toUpperCase()} portal with a ${role.toUpperCase()} account.`
          });
        }
        return sendJson(res, 200, { success: true, user: account });
      }

      // L. Parent Access Authorization Gate
      if (reqPath.startsWith('/api/parent/verify-access') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const parentId = urlParams.searchParams.get('parentId');
        const studentId = urlParams.searchParams.get('studentId');
        const parent = engine.FLEET_DATA.guardians[parentId];
        if (!parent) return sendJson(res, 404, { success: false, code: 'PARENT_NOT_FOUND', error: 'Parent record not found.' });
        const isAuthorized = parent.linkedStudentIds && parent.linkedStudentIds.includes(studentId);
        if (!isAuthorized) {
          return sendJson(res, 403, {
            success: false,
            code: 'UNAUTHORIZED_ACCESS',
            error: `Parent ${parentId} is not authorized to track student ${studentId}. Access denied.`
          });
        }
        return sendJson(res, 200, { success: true, authorized: true, parentId, studentId });
      }

      // M. Realtime Database Proxy Route
      if (reqPath.startsWith('/api/rtdb') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const rPath = urlParams.searchParams.get('path');
        const data = await engine.rtdbGet(rPath);
        return sendJson(res, 200, { success: true, data });
      }
      if (reqPath === '/api/fleet/export-trips-csv' && req.method === 'GET') {
        const csv = engine.exportTripsCsv();
        res.writeHead(200, {
          'Content-Type': 'text/csv',
          'Content-Disposition': 'attachment; filename="smart_campus_fleet_trips_log.csv"',
          'Access-Control-Allow-Origin': '*'
        });
        return res.end(csv);
      }

      // K. Auth Login with Strict Role Verification
      if (reqPath === '/api/auth/login' && req.method === 'POST') {
        const body = await parseJsonBody(req);
        const { email, password, expectedRole } = body;
        const cleanEmail = (email || '').trim().toLowerCase();

        let account = null;
        let role = null;

        // 1. Match Guardians / Parents
        for (const [uid, grd] of Object.entries(engine.FLEET_DATA.guardians)) {
          if (grd.email && grd.email.toLowerCase() === cleanEmail) {
            account = { ...grd, role: 'guardian', isEnabled: true };
            role = 'guardian';
            break;
          }
        }
        // 2. Match Drivers
        if (!account) {
          for (const [uid, drv] of Object.entries(engine.FLEET_DATA.drivers)) {
            if (drv.email && drv.email.toLowerCase() === cleanEmail) {
              account = { ...drv, role: 'driver' };
              role = 'driver';
              break;
            }
          }
        }
        // 3. Match Students
        if (!account) {
          for (const [uid, std] of Object.entries(engine.FLEET_DATA.students)) {
            const stdEmail = (std.email || `${std.name.toLowerCase().replace(/[^a-z]/g, '')}.student@campus.edu`).toLowerCase();
            const idEmail = `${std.id.replace('std_', '')}.student@campus.edu`;
            if (stdEmail === cleanEmail || idEmail === cleanEmail || cleanEmail.startsWith(std.id.replace('std_', '') + '@') || cleanEmail.startsWith(std.id.replace('std_', '') + '.')) {
              if (cleanEmail.includes('parent')) continue; // Guard against parent prefix
              account = { ...std, email: stdEmail, role: 'student', isEnabled: true };
              role = 'student';
              break;
            }
          }
        }
        // 4. Match Admins
        if (!account && (cleanEmail === 'admin@campus.edu' || cleanEmail === 'controlroom@campus.edu')) {
          account = { uid: 'admin_001', name: 'Campus Admin', email: cleanEmail, role: 'admin', isEnabled: true };
          role = 'admin';
        }

        if (!account) {
          return sendJson(res, 404, { success: false, code: 'USER_NOT_FOUND', error: 'No registered transportation account found.' });
        }
        if (password !== 'password123' && password !== 'admin123') {
          return sendJson(res, 401, { success: false, code: 'WRONG_PASSWORD', error: 'Invalid password.' });
        }
        if (account.isEnabled === false) {
          return sendJson(res, 403, { success: false, code: 'ACCOUNT_DISABLED', error: 'Your account has been deactivated.' });
        }
        if (expectedRole && expectedRole !== role) {
          return sendJson(res, 403, {
            success: false,
            code: 'ROLE_MISMATCH',
            error: `Access Denied: You are attempting to log into the ${expectedRole.toUpperCase()} portal with a ${role.toUpperCase()} account.`
          });
        }
        return sendJson(res, 200, { success: true, user: account });
      }

      // L. Parent Access Authorization Gate
      if (reqPath.startsWith('/api/parent/verify-access') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const parentId = urlParams.searchParams.get('parentId');
        const studentId = urlParams.searchParams.get('studentId');
        const parent = engine.FLEET_DATA.guardians[parentId];
        if (!parent) return sendJson(res, 404, { success: false, code: 'PARENT_NOT_FOUND', error: 'Parent record not found.' });
        const isAuthorized = parent.linkedStudentIds && parent.linkedStudentIds.includes(studentId);
        if (!isAuthorized) {
          return sendJson(res, 403, {
            success: false,
            code: 'UNAUTHORIZED_ACCESS',
            error: `Parent ${parentId} is not authorized to track student ${studentId}. Access denied.`
          });
        }
        return sendJson(res, 200, { success: true, authorized: true, parentId, studentId });
      }

      // M. Realtime Database Proxy Route
      if (reqPath.startsWith('/api/rtdb') && req.method === 'GET') {
        const urlParams = new URL(req.url, `http://${req.headers.host}`);
        const rPath = urlParams.searchParams.get('path');
        const data = await engine.rtdbGet(rPath);
        return sendJson(res, 200, { success: true, data });
      }

      return sendJson(res, 404, { error: "Unknown API route" });
    } catch (apiErr) {
      console.error(`[API Error] ${reqPath}:`, apiErr);
      return sendJson(res, 500, { error: apiErr.message, stack: apiErr.stack });
    }
  }

  // Static File Serving
  let filePath = path.join(WEB_DIR, reqPath === '/' ? 'index.html' : reqPath);
  if (reqPath.startsWith('/assets/')) {
    filePath = path.join(__dirname, '..', reqPath);
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(WEB_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end(`500 Server Error: ${err.message}`);
      } else {
        res.writeHead(200, {
          'Content-Type': contentType,
          'Cache-Control': 'no-cache, no-store, must-revalidate'
        });
        res.end(content);
      }
    });
  });
});

(async () => {
  await engine.initializeAuthoritativeDatabase();
  engine.startAuthoritativeTelemetryLoop();

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n=======================================================`);
    console.log(`SMART CAMPUS TRANSPORT: ENHANCED REAL-TIME SERVER RUNNING`);
    console.log(`Local Access URL: http://localhost:${PORT}`);
    console.log(`Firebase Target: https://gps-tracking-b76d8-default-rtdb.firebaseio.com`);
    console.log(`=======================================================\n`);
  });
})();
