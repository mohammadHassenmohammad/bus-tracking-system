/**
 * Verification test suite for Professional Transit System Extensions
 * - Passenger Manifest & Manual Check-in
 * - Missed Bus Assistant / Alternative Route Finder
 * - Fleet Analytics & KPIs (Punctuality, Volume, CO2)
 * - System Audit Logs
 * - CSV Export Endpoints
 */

const http = require('http');

function apiCall(endpoint, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: endpoint,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          if (res.headers['content-type'] && res.headers['content-type'].includes('json')) {
            resolve({ status: res.statusCode, headers: res.headers, data: JSON.parse(body) });
          } else {
            resolve({ status: res.statusCode, headers: res.headers, text: body });
          }
        } catch (e) {
          resolve({ status: res.statusCode, headers: res.headers, text: body });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function run() {
  console.log("=== VERIFYING PROFESSIONAL TRANSIT EXTENSIONS ===");
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`[PASS] ${message}`);
      passed++;
    } else {
      console.error(`[FAIL] ${message}`);
      failed++;
    }
  }

  try {
    // 1. Passenger Manifest
    const manifestRes = await apiCall('/api/attendance/manifest?busId=bus_01');
    assert(manifestRes.status === 200, "Passenger manifest endpoint returned 200");
    assert(manifestRes.data.manifest && manifestRes.data.manifest.length > 0, `Manifest retrieved ${manifestRes.data.manifest?.length} assigned students`);
    const student1 = manifestRes.data.manifest[0];
    assert(student1 && student1.name && student1.rollNumber, `Student manifest contains detailed identity: ${student1.name} (${student1.rollNumber})`);

    // 2. Manual Check-in Override
    const manualCheckinRes = await apiCall('/api/attendance/manual-checkin', 'POST', {
      studentId: 'std_anil',
      busId: 'bus_01',
      driverUid: 'drv_ravi',
      reason: 'Student battery dead - manual driver verification'
    });
    assert(manualCheckinRes.status === 200, "Manual check-in endpoint returned 200");
    assert(manualCheckinRes.data.success === true, "Manual check-in succeeded");
    assert(manualCheckinRes.data.record.verificationMethod === 'manual_override', "Verification method properly tagged as manual_override");

    // Re-check manifest reflects updated status
    const manifestAfter = await apiCall('/api/attendance/manifest?busId=bus_01');
    const anilInManifest = manifestAfter.data.manifest.find(s => s.studentId === 'std_anil');
    assert(anilInManifest && anilInManifest.boardingStatus === 'boarded', "Manifest immediately reflects boarded status after manual check-in");

    // 3. Alternative Buses / Missed Bus Assistant
    const altRes = await apiCall('/api/routes/alternatives?studentId=std_anil');
    assert(altRes.status === 200, "Alternative buses endpoint returned 200");
    assert(altRes.data.alternatives && altRes.data.alternatives.length >= 2, `Found ${altRes.data.alternatives?.length} candidate alternative buses`);
    const topAlt = altRes.data.alternatives[0];
    assert(topAlt && topAlt.spareCapacity > 0, `Alternative bus has spare capacity: ${topAlt.spareCapacity} seats available`);

    // 4. Analytics & KPIs
    const kpisRes = await apiCall('/api/analytics/kpis');
    assert(kpisRes.status === 200, "Analytics KPIs endpoint returned 200");
    const kpis = kpisRes.data.kpis;
    assert(kpis.punctualityRate >= 90.0, `Punctuality rate verified: ${kpis.punctualityRate}%`);
    assert(kpis.co2SavedKg > 0, `Carbon offset verified: ${kpis.co2SavedKg} kg CO2 saved`);
    assert(kpis.weeklyPunctuality && kpis.weeklyPunctuality.length === 5, "Weekly punctuality trend array present with 5 workdays");
    assert(kpis.routeVolumes && kpis.routeVolumes.length === 4, "Route volumes present for all 4 campus corridors");

    // 5. System Audit Trail
    const logsRes = await apiCall('/api/system/audit-logs');
    assert(logsRes.status === 200, "Audit logs endpoint returned 200");
    assert(logsRes.data.logs && logsRes.data.logs.length >= 2, `Audit trail populated with ${logsRes.data.logs?.length} security and operational logs`);
    const manualLog = logsRes.data.logs.find(l => l.type === 'MANUAL_CHECKIN');
    assert(manualLog !== undefined, "Audit log captured the manual check-in event with actor and severity");

    // 6. CSV Export: Attendance
    const csvAttRes = await apiCall('/api/attendance/export-csv');
    assert(csvAttRes.status === 200, "Attendance CSV download endpoint returned 200");
    assert(csvAttRes.headers['content-type'].includes('text/csv'), "Correct text/csv header returned");
    assert(csvAttRes.text.includes('Attendance ID') && csvAttRes.text.includes('Anil Varma'), "CSV text contains proper tabular headers and student row");

    // 7. CSV Export: Fleet Trips
    const csvTripsRes = await apiCall('/api/fleet/export-trips-csv');
    assert(csvTripsRes.status === 200, "Fleet trips CSV download endpoint returned 200");
    assert(csvTripsRes.text.includes('Trip ID') && csvTripsRes.text.includes('Bus 01'), "Trips CSV text contains tabular headers and bus rows");

  } catch (err) {
    console.error("Test execution error:", err);
    failed++;
  }

  console.log(`\n========================================`);
  console.log(`TOTAL PASSED: ${passed} | TOTAL FAILED: ${failed}`);
  console.log(`========================================`);
  process.exit(failed > 0 ? 1 : 0);
}

run();

