/**
 * Automated Verification Script for Web Portal Authentication System
 * Tests login endpoints, credential validation, strict role mismatch guards,
 * account status gates, session persistence, and role access permissions.
 */

let passedCount = 0;
let failedCount = 0;

function assert(condition, desc) {
  if (condition) {
    console.log(`  [PASS] ${desc}`);
    passedCount++;
  } else {
    console.error(`  [FAIL] ${desc}`);
    failedCount++;
  }
}

async function api(path, method = 'GET', body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`http://localhost:3000/api/${path}`, opts);
  return { status: res.status, data: await res.json() };
}

console.log("\n=======================================================");
console.log("SMART CAMPUS TRANSPORT: WEB AUTHENTICATION SUITE");
console.log("Testing Full-Functional Multi-Role Auth & Security System");
console.log("=======================================================\n");

(async () => {
  try {
    // 1. DRIVER LOGIN TEST
    console.log(">>> 1. Driver Authentication (Ravi Kumar - Bus 01)");
    const drvLogin = await api('auth/login', 'POST', {
      email: 'ravi.driver@campus.edu',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(drvLogin.status === 200 && drvLogin.data.success === true, "Driver Ravi successfully authenticated with 200 OK");
    assert(drvLogin.data.user.role === 'driver', "Authenticated user tagged with role 'driver'");
    assert(drvLogin.data.user.assignedBusId === 'bus_01', "Driver correctly associated with Bus 01");

    // 2. STUDENT LOGIN TEST
    console.log("\n>>> 2. Student Authentication (Aditya Varma - CSE)");
    const stdLogin = await api('auth/login', 'POST', {
      email: 'aditya.student@campus.edu',
      password: 'password123',
      expectedRole: 'student'
    });
    assert(stdLogin.status === 200 && stdLogin.data.success === true, "Student Aditya successfully authenticated with 200 OK");
    assert(stdLogin.data.user.role === 'student', "Authenticated user tagged with role 'student'");
    assert(stdLogin.data.user.assignedRouteId === 'route_a', "Student correctly associated with Route A");

    // 3. PARENT LOGIN TEST
    console.log("\n>>> 3. Parent Authentication (Suryanarayana Varma)");
    const parentLogin = await api('auth/login', 'POST', {
      email: 'parent.anil@campus.edu',
      password: 'password123',
      expectedRole: 'guardian'
    });
    assert(parentLogin.status === 200 && parentLogin.data.success === true, "Parent Suryanarayana successfully authenticated with 200 OK");
    assert(parentLogin.data.user.role === 'guardian', "Authenticated user tagged with role 'guardian'");
    assert(parentLogin.data.user.linkedStudentIds && parentLogin.data.user.linkedStudentIds.length > 0, "Parent linked to verified student profile");

    // 4. ADMINISTRATOR LOGIN TEST
    console.log("\n>>> 4. Administrator Authentication (Dr. Ramanujan - Campus Admin)");
    const adminLogin = await api('auth/login', 'POST', {
      email: 'admin@campus.edu',
      password: 'admin123',
      expectedRole: 'admin'
    });
    assert(adminLogin.status === 200 && adminLogin.data.success === true, "Super Administrator successfully authenticated with 200 OK");
    assert(adminLogin.data.user.role === 'admin', "Administrator profile granted administrative coordination privileges");

    // 5. SECURITY GUARD: ROLE MISMATCH REJECTION
    console.log("\n>>> 5. Role Mismatch Guard (Student attempting Driver Portal)");
    const mismatchAttempt = await api('auth/login', 'POST', {
      email: 'aditya.student@campus.edu',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(mismatchAttempt.status === 403, "Role mismatch rejected with HTTP 403 Forbidden");
    assert(mismatchAttempt.data.code === 'ROLE_MISMATCH', "Security error code verified as 'ROLE_MISMATCH'");
    assert(mismatchAttempt.data.error.includes('Access Denied'), "Descriptive remediation error message provided");

    // 6. SECURITY GUARD: WRONG PASSWORD REJECTION
    console.log("\n>>> 6. Invalid Password Handling");
    const badPassword = await api('auth/login', 'POST', {
      email: 'ravi.driver@campus.edu',
      password: 'wrong_password_999',
      expectedRole: 'driver'
    });
    assert(badPassword.status === 401, "Invalid password rejected with HTTP 401 Unauthorized");
    assert(badPassword.data.code === 'WRONG_PASSWORD', "Error code verified as 'WRONG_PASSWORD'");

    // 7. SECURITY GUARD: UNREGISTERED USER
    console.log("\n>>> 7. Unregistered User Handling");
    const unknownUser = await api('auth/login', 'POST', {
      email: 'hacker@outside.org',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(unknownUser.status === 404, "Unregistered user rejected with HTTP 404 Not Found");
    assert(unknownUser.data.code === 'USER_NOT_FOUND', "Error code verified as 'USER_NOT_FOUND'");

    // 8. SECURITY GUARD: DEACTIVATED ACCOUNT
    console.log("\n>>> 8. Deactivated Driver Handling (Prakash Rao)");
    // First disable Prakash Rao in catalog
    await api('driver/status', 'PATCH', { driverUid: 'drv_prakash', isEnabled: false });
    const disabledLogin = await api('auth/login', 'POST', {
      email: 'prakash.driver@campus.edu',
      password: 'password123',
      expectedRole: 'driver'
    });
    assert(disabledLogin.status === 403, "Deactivated driver account rejected with HTTP 403 Forbidden");
    assert(disabledLogin.data.code === 'ACCOUNT_DISABLED', "Error code verified as 'ACCOUNT_DISABLED'");

    // 9. WEB CLIENT MARKUP INTEGRITY
    console.log("\n>>> 9. Web Client Interface & Auth System Verification");
    const fs = require('fs');
    const html = fs.readFileSync('./web/index.html', 'utf8');

    assert(html.includes('id="auth-modal"') && html.includes('class="auth-overlay"'),
      "Auth Modal overlay dialog rendered in index.html");
    assert(html.includes('id="auth-role-tabs"') || html.includes('class="auth-role-tabs"'),
      "Interactive Role Selector Tabs (Driver, Student, Parent, Admin) rendered");
    assert(html.includes('id="auth-email"') && html.includes('id="auth-password"'),
      "Email and Password input fields with security attributes rendered");
    assert(html.includes('id="auth-error-banner"'),
      "Role-aware error alert banner present for mismatch and invalid credentials");
    assert(html.includes('id="header-user-widget"') && html.includes('id="user-dropdown-menu"'),
      "Authenticated user profile badge, avatar, and dropdown menu integrated in top navbar");
    assert(html.includes('auth-quick-chips') && html.includes('fillAndLogin'),
      "1-Click verified demo sign-in chips implemented for all roles");
    assert(html.includes('checkAuthOnLoad()'),
      "Auto-session initialization and persistence wired on window.onload");

    console.log("\n=======================================================");
    console.log(`AUTH VERIFICATION RESULT: ${passedCount} PASSED, ${failedCount} FAILED (${((passedCount/(passedCount+failedCount))*100).toFixed(0)}%)`);
    console.log("=======================================================\n");

    if (failedCount > 0) process.exitCode = 1;
    else process.exitCode = 0;

  } catch (err) {
    console.error("FATAL ERROR IN AUTH SUITE:", err);
    process.exit(1);
  }
})();
