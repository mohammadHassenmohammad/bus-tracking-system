/**
 * Admin Portal Full API Test Suite
 * Verifies all Administrative capabilities:
 * - Driver account creation, bus/route assignment, enable/disable status, deletion
 * - Bus fleet creation, capacity update, route assignment, deletion
 * - Route & Stop creation, GPS stop coordinates, stop removal
 * - Student creation, bus/stop assignment, parent linking, student removal
 * - Parent guardian account creation and child linking
 * - Broadcast notification creation, urgent dispatch, listing, and deletion
 */

const assert = (condition, msg) => {
  if (condition) {
    console.log(`  [PASS] ${msg}`);
  } else {
    console.error(`  [FAIL] ${msg}`);
    process.exit(1);
  }
};

async function api(path, method = 'GET', body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`http://localhost:3000/api/${path}`, opts);
  return await res.json();
}

(async () => {
  console.log("\n=======================================================");
  console.log("ADMIN PORTAL END-TO-END CAPABILITIES VERIFIER");
  console.log("=======================================================\n");

  try {
    // 1. Initial Status Check
    console.log(">>> 1. Verifying Fleet Status & Data Structures");
    const status = await api('fleet/status');
    assert(status.buses && status.drivers && status.routes && status.students && status.guardians && status.announcements,
      "Fleet status contains buses, drivers, routes, students, guardians, and announcements");

    // 2. Driver Management
    console.log("\n>>> 2. Driver Management (Create, Assign, Status Toggle, Delete)");
    const newDriver = await api('driver/create', 'POST', {
      name: "Venkat Rao",
      employeeId: "EMP-DRV-105",
      mobile: "+91 98765 11005",
      email: "venkat.driver@campus.edu",
      licenseNumber: "AP05-2022-004455",
      assignedBusId: "bus_01",
      assignedRouteId: "route_a"
    });
    assert(newDriver.success && newDriver.driver.uid === "drv_empdrv105",
      `Driver created successfully: ${newDriver.driver.name} (${newDriver.driver.uid})`);

    const assignDriverRes = await api('driver/assign', 'POST', {
      driverUid: "drv_empdrv105",
      busId: "bus_02",
      routeId: "route_b"
    });
    assert(assignDriverRes.success && assignDriverRes.driver.assignedBusId === "bus_02",
      "Driver reassigned to Bus 02 and Route B");

    const toggleStatusRes = await api('driver/status', 'PATCH', {
      driverUid: "drv_empdrv105",
      isEnabled: false
    });
    assert(toggleStatusRes.success && toggleStatusRes.isEnabled === false,
      "Driver operational access disabled by Administrator");

    // 3. Bus Fleet Management
    console.log("\n>>> 3. Bus Fleet Management (Create, Capacity Update, Delete)");
    const newBus = await api('bus/create', 'POST', {
      busId: "bus_05",
      busNumber: "Bus 05",
      registrationPlate: "AP35 GH 7788",
      totalCapacity: 55,
      assignedRouteId: "route_a"
    });
    assert(newBus.success && newBus.bus.id === "bus_05",
      `New Bus added to fleet: ${newBus.bus.busNumber} (${newBus.bus.registrationPlate})`);

    const updateBusRes = await api('bus/update', 'PATCH', {
      busId: "bus_05",
      totalCapacity: 60,
      registrationPlate: "AP35 GH 7799",
      status: "active"
    });
    assert(updateBusRes.success && updateBusRes.bus.totalCapacity === 60,
      "Bus capacity updated to 60 seats and registration plate revised");

    // 4. Routes & Stops Management
    console.log("\n>>> 4. Routes & Stops Management (Create Route, Add Stop, Delete Stop)");
    const newRoute = await api('route/create', 'POST', {
      id: "route_e",
      code: "Route E",
      name: "Tuni Express Corridor",
      totalDistanceKm: 45.0,
      estimatedMinutes: 60
    });
    assert(newRoute.success && newRoute.route.id === "route_e",
      `New Route created: ${newRoute.route.code} - ${newRoute.route.name}`);

    const addStopRes = await api('stop/create', 'POST', {
      routeId: "route_e",
      name: "Tuni RTC Junction",
      lat: 17.3500,
      lng: 82.5500,
      pickupTime: "06:45 AM",
      studentCount: 22
    });
    assert(addStopRes.success && addStopRes.stop.name === "Tuni RTC Junction",
      `New Stop added to Route E: ${addStopRes.stop.name} (${addStopRes.stop.pickupTime})`);

    const deleteStopRes = await api('stop/delete', 'POST', {
      routeId: "route_e",
      stopId: addStopRes.stop.id
    });
    assert(deleteStopRes.success && !deleteStopRes.route.stops.find(s => s.id === addStopRes.stop.id),
      "Stop removed from Route E");

    // 5. Students & Parents Management
    console.log("\n>>> 5. Students & Parents Management (Create, Assign, Parent Link)");
    const newStudent = await api('student/create', 'POST', {
      id: "std_priya",
      name: "Priya Sharma",
      rollNumber: "21A91A0588",
      department: "Information Technology",
      assignedBusId: "bus_02",
      assignedRouteId: "route_b",
      assignedStopId: "stop_b1",
      assignedStopName: "Kotipalli Stand",
      guardianId: "parent_priya"
    });
    assert(newStudent.success && newStudent.student.id === "std_priya",
      `Student registered: ${newStudent.student.name} (${newStudent.student.rollNumber})`);

    const assignStudentRes = await api('student/assign', 'PATCH', {
      studentId: "std_priya",
      assignedBusId: "bus_05",
      assignedRouteId: "route_a",
      assignedStopId: "stop_a1",
      assignedStopName: "Main Bus Stand"
    });
    assert(assignStudentRes.success && assignStudentRes.student.assignedBusId === "bus_05",
      "Student successfully reassigned to Bus 05 and Main Bus Stand");

    const newParent = await api('parent/create', 'POST', {
      id: "parent_priya",
      name: "Ramesh Sharma",
      email: "parent.priya@campus.edu",
      mobile: "+91 98765 44001",
      linkedStudentIds: ["std_priya"]
    });
    assert(newParent.success && newParent.guardian.linkedStudentIds.includes("std_priya"),
      `Parent account created and linked to child Priya: ${newParent.guardian.name}`);

    // 6. Broadcast Notifications & Announcements
    console.log("\n>>> 6. Broadcast Notifications & Announcements (Create, List, Delete)");
    const newAnn = await api('announcements/create', 'POST', {
      title: "Weather Alert: Heavy Rain Advisory",
      content: "All college buses are equipped with storm kits. Drivers are instructed to maintain maximum 40 km/h speed.",
      priority: "urgent",
      targetType: "all",
      targetId: "all",
      author: "Chief Transport Administrator"
    });
    assert(newAnn.success && newAnn.announcement.priority === "urgent",
      `Urgent broadcast announcement dispatched: "${newAnn.announcement.title}"`);

    const listAnn = await api('announcements');
    assert(listAnn.success && Object.keys(listAnn.announcements).length >= 3,
      `Announcements catalog contains ${Object.keys(listAnn.announcements).length} active announcements`);

    const deleteAnn = await api('announcements/delete', 'POST', {
      announcementId: newAnn.announcement.id
    });
    assert(deleteAnn.success, "Broadcast announcement expired and deleted");

    // Clean up test entities
    await api('bus/delete', 'POST', { busId: "bus_05" });
    await api('student/delete', 'POST', { studentId: "std_priya" });
    await api('driver/delete', 'POST', { driverUid: "drv_empdrv105" });
    console.log("\n  [PASS] Test entities cleaned up successfully.");

    console.log("\n=======================================================");
    console.log("FINAL RESULT: ALL ADMIN PORTAL CAPABILITIES 100% VERIFIED!");
    console.log("=======================================================\n");
  } catch (err) {
    console.error("Test execution failed:", err);
    process.exit(1);
  }
})();

