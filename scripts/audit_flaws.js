const fs = require('fs');
const path = require('path');

console.log("=== COMPREHENSIVE MULTI-SYSTEM FLAW DETECTOR ===\n");

// 1. Audit all getElementById across web/index.html
const htmlPath = path.join(__dirname, '../web/index.html');
const html = fs.readFileSync(htmlPath, 'utf8');

const getElemRegex = /getElementById\(['"]([^'"]+)['"]\)/g;
let match;
const elemIds = new Set();
while ((match = getElemRegex.exec(html)) !== null) {
  elemIds.add(match[1]);
}
console.log(`Checking ${elemIds.size} getElementById references in web/index.html...`);
const missingIds = [];
for (const id of elemIds) {
  if (!html.includes(`id="${id}"`) && !html.includes(`id='${id}'`)) {
    missingIds.push(id);
  }
}
if (missingIds.length > 0) {
  console.log("  [FLAW FOUND] Missing DOM elements:", missingIds);
} else {
  console.log("  [OK] All DOM elements exist!");
}

// 2. Audit API endpoints in web/index.html vs start_server.js
console.log("\nAuditing fetch endpoints in web/index.html vs start_server.js...");
const fetchRegex = /fetch\(['"](?:\/api\/|http:\/\/localhost:3000\/api\/)([^'?"`]+)/g;
const clientEndpoints = new Set();
while ((match = fetchRegex.exec(html)) !== null) {
  clientEndpoints.add(match[1]);
}

const serverPath = path.join(__dirname, 'start_server.js');
const serverCode = fs.readFileSync(serverPath, 'utf8');

const unhandledEndpoints = [];
for (const ep of clientEndpoints) {
  // check if serverCode contains this route
  if (!serverCode.includes(ep) && !serverCode.includes('/api/' + ep)) {
    unhandledEndpoints.push(ep);
  }
}
if (unhandledEndpoints.length > 0) {
  console.log("  [FLAW FOUND] Client endpoints not explicitly routed in start_server.js:", unhandledEndpoints);
} else {
  console.log("  [OK] All client endpoints have matching server handlers!");
}

// 3. Audit Flutter Dart files for missing imports and class references
console.log("\nAuditing Flutter Dart files in lib/...");
function getFiles(dir, ext) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(getFiles(file, ext));
    } else if (file.endsWith(ext)) {
      results.push(file);
    }
  });
  return results;
}

const dartFiles = getFiles(path.join(__dirname, '../lib'), '.dart');
console.log(`Auditing ${dartFiles.length} Dart files...`);

const missingDartImports = [];
for (const df of dartFiles) {
  const content = fs.readFileSync(df, 'utf8');
  const importRegex = /import\s+['"]([^'"]+)['"];/g;
  let imp;
  while ((imp = importRegex.exec(content)) !== null) {
    const importPath = imp[1];
    if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
      // package or Dart SDK built-in imports
      continue;
    }
    // relative import
    const resolvedPath = path.resolve(path.dirname(df), importPath);
    if (!fs.existsSync(resolvedPath)) {
      missingDartImports.push({ file: path.basename(df), import: importPath });
    }
  }
}

if (missingDartImports.length > 0) {
  console.log("  [FLAW FOUND] Broken Dart relative imports:", missingDartImports);
} else {
  console.log("  [OK] All relative Dart imports resolve to existing files!");
}

// 4. Check for UI / Logic flaws in Parent and Student Views
console.log("\nAuditing Parent and Student View Logic in web/index.html...");
// Check if student view displays accurate data
const studentCheck = html.includes('std_aditya') || html.includes('std_anil');
console.log("  Student default data configured:", studentCheck ? "Yes" : "No");

// Check if parent child switcher handles multiple children
const parentChildSwitcher = html.includes('parent-child-select') || html.includes('parent-child-tabs');
console.log("  Parent child switcher present:", parentChildSwitcher ? "Yes" : "No");

// Check if driver live controls handle pause/resume accurately
const driverControls = html.includes('btn-pause-trip') || html.includes('pauseTrip') || html.includes('btn-driver-pause') || html.includes('driverPauseTrip');
console.log("  Driver pause/resume handlers present:", driverControls ? "Yes" : "No");
