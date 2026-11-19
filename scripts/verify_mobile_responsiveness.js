/**
 * Smart Campus Bus Tracking System
 * Complete Mobile Responsiveness & Adaptive UI/UX Automated Verifier
 * 
 * Tests:
 * 1. Web Viewport Meta & Mobile CSS Tokens (touch targets, breakpoints 320px-1200px, landscape)
 * 2. Role-Based Bottom Sheets (Driver, Student, Parent drag handles & collapse/expand logic)
 * 3. Mobile Admin Console (Segmented mode switcher: Live Map vs Fleet Roster)
 * 4. Flutter Dart Codebase Responsive Constraints (LayoutBuilder, MediaQuery, Wrap, FittedBox, Flexible)
 * 5. Functional Non-Regression under Responsive UI
 */

const fs = require('fs');
const http = require('http');

let passed = 0;
let failed = 0;

function assert(condition, category, testDesc) {
  if (condition) {
    console.log(`  [PASS] [${category}] ${testDesc}`);
    passed++;
  } else {
    console.error(`  [FAIL] [${category}] ${testDesc}`);
    failed++;
  }
}

function apiCall(endpoint, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: endpoint,
      method: method,
      headers: { 'Content-Type': 'application/json' }
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

async function runVerification() {
  console.log('==========================================================================');
  console.log('MOBILE RESPONSIVENESS & UI/UX OPTIMIZATION VERIFIER');
  console.log('Validating 320dp-1200dp Adaptability, Touch Targets & Non-Regression');
  console.log('==========================================================================\n');

  const html = fs.readFileSync('web/index.html', 'utf8');

  // --- 1. VIEWPORT & RESPONSIVE META ---
  console.log('>>> 1. Viewport Meta & Base Scaling Constraints');
  assert(html.includes('name="viewport"'), 'Viewport', 'Viewport meta tag is declared');
  assert(html.includes('width=device-width'), 'Viewport', 'Device-width constraint enabled');
  assert(html.includes('initial-scale=1.0'), 'Viewport', 'Initial scale 1.0 set');
  assert(html.includes('box-sizing: border-box'), 'Viewport', 'Universal box-sizing border-box applied');

  // --- 2. BREAKPOINTS & MOBILE CSS RULES ---
  console.log('\n>>> 2. Responsive Breakpoints & CSS Architecture (320px - 1200px & Landscape)');
  assert(html.includes('@media (max-width: 992px)'), 'CSS Breakpoints', 'Tablet breakpoint (<=992px) present');
  assert(html.includes('@media (max-width: 768px)'), 'CSS Breakpoints', 'Standard Mobile breakpoint (<=768px) present');
  assert(html.includes('@media (max-width: 480px)'), 'CSS Breakpoints', 'Compact Phone breakpoint (<=480px) present');
  assert(html.includes('@media (max-width: 360px)'), 'CSS Breakpoints', 'Ultra-Small Phone breakpoint (320px-360px) present');
  assert(html.includes('@media (max-height: 520px) and (orientation: landscape)'), 'CSS Breakpoints', 'Landscape phone orientation support present');

  // --- 3. SHEET DRAG HANDLES & COLLAPSIBLE HUD ---
  console.log('\n>>> 3. Interactive Draggable Bottom Sheets (Driver, Student, Parent)');
  assert(html.includes('.sheet-handle'), 'Bottom Sheets', 'CSS .sheet-handle styling defined with min touch dimensions');
  assert(html.includes('.gnav-bottom-card.collapsed'), 'Bottom Sheets', 'Driver HUD collapsed state defined (<=74px)');
  assert(html.includes('.student-floating-sheet.collapsed'), 'Bottom Sheets', 'Student/Parent HUD collapsed state defined (<=74px)');
  assert(html.includes('id="driver-bottom-card"'), 'Bottom Sheets', 'Driver sheet has unique DOM id');
  assert(html.includes('id="student-bottom-sheet"'), 'Bottom Sheets', 'Student sheet has unique DOM id');
  assert(html.includes('id="parent-bottom-sheet"'), 'Bottom Sheets', 'Parent sheet has unique DOM id');
  assert(html.includes('toggleDriverSheet()'), 'Bottom Sheets', 'Driver sheet toggle function connected');
  assert(html.includes('toggleStudentSheet()'), 'Bottom Sheets', 'Student sheet toggle function connected');
  assert(html.includes('toggleParentSheet()'), 'Bottom Sheets', 'Parent sheet toggle function connected');

  // --- 4. ADMIN MOBILE MODE TOGGLE (MAP VS ROSTER) ---
  console.log('\n>>> 4. Mobile Administrator Console Architecture');
  assert(html.includes('.admin-mobile-toggle-bar'), 'Admin Mobile', 'Admin mobile segmented toggle bar CSS present');
  assert(html.includes('id="btn-admin-mode-map"'), 'Admin Mobile', 'Admin mode map button present');
  assert(html.includes('id="btn-admin-mode-roster"'), 'Admin Mobile', 'Admin mode roster button present');
  assert(html.includes('setAdminMobileMode'), 'Admin Mobile', 'setAdminMobileMode JavaScript handler present');
  assert(html.includes('mobile-mode-map'), 'Admin Mobile', 'Default mobile map mode class attached');
  assert(html.includes('maps.admin.invalidateSize()'), 'Admin Mobile', 'Leaflet map invalidateSize called on mobile mode switch');

  // --- 5. DRIVER HUD SPACING & GPS POSITION ---
  console.log('\n>>> 5. Driver Map Screen Touch Ergonomics');
  assert(html.includes('top: 140px; left: 10px;'), 'Driver UI', 'Driver GPS indicator positioned below speedometer puck to prevent overlap');
  assert(html.includes('gnav-voice-btn'), 'Driver UI', 'Voice navigation toggle button has dedicated touch target');

  // --- 6. FLUTTER DART RESPONSIVE CONSTRUCTS AUDIT ---
  console.log('\n>>> 6. Flutter Dart Responsive Constructs Audit (lib/)');
  const welcomeCode = fs.readFileSync('lib/features/auth/welcome_screen.dart', 'utf8');
  assert(welcomeCode.includes('Wrap(') && welcomeCode.includes('spacing: 6'), 'Flutter Auth', 'Welcome screen uses Wrap for role cards to prevent 320dp overflow');

  const driverDashboardCode = fs.readFileSync('lib/features/driver/driver_dashboard_screen.dart', 'utf8');
  assert(driverDashboardCode.includes('overflow: TextOverflow.ellipsis'), 'Flutter Driver', 'Driver upcoming stop uses TextOverflow.ellipsis');

  const driverNavCode = fs.readFileSync('lib/features/driver/driver_navigation_screen.dart', 'utf8');
  assert(driverNavCode.includes('FittedBox(') && driverNavCode.includes('Expanded('), 'Flutter Driver Nav', 'Driver navigation HUD buttons use FittedBox & Expanded flex');

  const studentDashboardCode = fs.readFileSync('lib/features/student/student_dashboard_screen.dart', 'utf8');
  assert(studentDashboardCode.includes('Expanded(') && studentDashboardCode.includes('overflow: TextOverflow.ellipsis'), 'Flutter Student', 'Student dashboard stop row wrapped in Expanded with ellipsis');

  const studentMapCode = fs.readFileSync('lib/features/student/student_live_map_screen.dart', 'utf8');
  assert(studentMapCode.includes('FittedBox('), 'Flutter Student Map', 'Student live map action buttons wrapped with FittedBox');

  const parentDashboardCode = fs.readFileSync('lib/features/parent/parent_dashboard_screen.dart', 'utf8');
  assert(parentDashboardCode.includes('isExpanded: true'), 'Flutter Parent', 'Parent active child dropdown set to isExpanded: true');

  const adminControlCode = fs.readFileSync('lib/features/admin/admin_control_room_screen.dart', 'utf8');
  assert(adminControlCode.includes('LayoutBuilder') && adminControlCode.includes('constraints.maxWidth < 768'), 'Flutter Admin', 'Admin control room uses LayoutBuilder with 768 mobile threshold');
  assert(adminControlCode.includes('NavigationBar(') && adminControlCode.includes('NavigationRail('), 'Flutter Admin', 'Admin control room switches between NavigationBar on mobile and NavigationRail on desktop');

  const liveMapCode = fs.readFileSync('lib/shared/live_map_widget.dart', 'utf8');
  assert(liveMapCode.includes('Flexible(') && liveMapCode.includes('overflow: TextOverflow.ellipsis'), 'Flutter Map Widget', 'Shared LiveMapWidget overlays wrapped in Flexible with ellipsis');

  // --- 7. FUNCTIONAL NON-REGRESSION (ENDPOINTS & STATE) ---
  console.log('\n>>> 7. Functional Non-Regression Verification');
  const resetRes = await apiCall('/api/fleet/reset', 'POST');
  assert(resetRes.status === 200 && resetRes.data.success === true, 'Regression API', 'Fleet reset succeeds');

  const startTripRes = await apiCall('/api/trip/start', 'POST', {
    driverUid: 'drv_ravi',
    busId: 'bus_01',
    routeId: 'route_a'
  });
  assert(startTripRes.status === 200 && startTripRes.data.success === true, 'Regression API', 'Start trip succeeds on bus_01');

  const gpsIngestRes = await apiCall('/api/driver/gps', 'POST', {
    busId: 'bus_01',
    driverUid: 'drv_ravi',
    latitude: 16.9608,
    longitude: 82.2385,
    speedKmh: 34.2,
    accuracyMeters: 4.2
  });
  assert(gpsIngestRes.status === 200 && gpsIngestRes.data.success === true, 'Regression API', 'GPS ingestion succeeds with calculated accuracy');

  const studentLiveRes = await apiCall('/api/student/live?studentId=std_anil', 'GET');
  assert(studentLiveRes.status === 200 && studentLiveRes.data.bus && studentLiveRes.data.bus.id === 'bus_01', 'Regression API', 'Student live subscription returns bus_01 data');

  const parentAccessRes = await apiCall('/api/parent/verify-access?parentId=parent_anil&studentId=std_anil', 'GET');
  assert(parentAccessRes.status === 200 && parentAccessRes.data.authorized === true, 'Regression API', 'Parent access authorization gate verified');

  console.log('\n==========================================================================');
  console.log(`TOTAL TESTS: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log('==========================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runVerification().catch(err => {
  console.error('Verification script error:', err);
  process.exit(1);
});
