# Smart Campus Transport: Deployment, Run & Verification Guide

## 1. Quick Start & Execution

### Running the Flutter Web & Mobile Application
```bash
# In the project root directory
flutter pub get

# To run the Flutter Web Control Room & Mobility Portal
flutter run -d chrome

# To run on connected Android device / emulator
flutter run -d android
```

### Running Automated Test Suite
```bash
# Execute full algorithmic, GIS, and security test suite
node scripts/run_automated_tests.js

# Execute scientific research benchmarks and generate CSV datasets
node scripts/run_research_benchmarks.js
```

---

## 2. Pre-Configured Test Accounts (5 System Roles)

Use the integrated role switcher bar across the top of the application to switch roles instantly, or use these credentials:

| Role | Name | Email | Password | Default Assignment |
| :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | Dr. R. Ramanujan | `admin@campus.edu` | `Admin@2026` | Full Campus Fleet Authority |
| **Transport Coordinator** | Prof. K. Venkatesh | `controlroom@campus.edu` | `Coord@2026` | Central Fleet Control Room |
| **Bus Driver** | M. S. Prasad | `driver.b1@campus.edu` | `Driver@2026` | Bus 12 (Kakinada Express) |
| **Student** | Aditya Varma | `student1@campus.edu` | `Student@2026` | Bus 12, Madhavapatnam Stop |
| **Parent / Guardian** | Suryanarayana Varma | `parent1@campus.edu` | `Parent@2026` | Linked Child: Aditya Varma |

---

## 3. Firebase Local Emulator Suite Setup (₹0 Cost)

This project is configured out-of-the-box to run locally with zero external cloud dependencies or costs using the Firebase Local Emulator Suite.

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Start Auth, Firestore, and Realtime Database emulators
firebase emulators:start
```

The emulators run on the following ports:
- **Emulator UI:** `http://localhost:4000`
- **Authentication:** `http://localhost:9099`
- **Cloud Firestore:** `http://localhost:8080`
- **Realtime Database:** `http://localhost:9000`

---

## 4. Real-Device GPS Tracking Instructions

To run physical tracking with an Android smartphone:
1. Open the **Driver Application** on the driver's device.
2. Grant the required permissions:
   - `ACCESS_FINE_LOCATION`
   - `ACCESS_COARSE_LOCATION`
   - `FOREGROUND_SERVICE_LOCATION`
3. Tap **"Start Trip"**.
4. An ongoing persistent Android foreground notification will appear:
   *`"Smart Campus Transport • Active GPS tracking on Bus 12"`*.
5. Position updates stream to `/liveLocations/bus_01` in Firebase Realtime Database at 3-second intervals.
6. When stationary at a stop for over 30 seconds, the rate throttles automatically to 10 seconds to conserve battery and cloud writes.

---

## 5. Free-Tier Resource Consumption & Cost Breakdown (Target: ₹0)

| Service | Spark Free Limit | 5-Bus Fleet Peak Usage | Headroom Remaining |
| :--- | :--- | :--- | :--- |
| **Realtime Database Writes**| 20,000 writes / day | ~18,400 writes / day (4 hrs active peak at 3s updates + stationary throttle) | 8.0% safety buffer |
| **Realtime Database Bandwidth**| 10 GB / month | ~0.78 GB / month (180 bytes/write) | 92.2% buffer |
| **Cloud Firestore Reads** | 50,000 reads / day | ~3,200 reads / day (cached static routes & stops) | 93.6% buffer |
| **Cloud Firestore Writes**| 20,000 writes / day | ~350 writes / day (attendance + incidents) | 98.2% buffer |
| **Firebase Authentication**| Unlimited email/pass | 50 demo accounts | Unlimited |
| **Total Monthly Cost** | **₹0.00** | **₹0.00** | **₹0.00** |

---

## 6. Academic Research Data Verification

All experimental benchmarks from Section 24 have been executed with deterministic mathematical parameters. Output CSV files are located in `assets/research/`:
- `exp1_eta_comparison.csv`: Baseline vs Enhanced Predictive ETA (MAE, RMSE, MedAE).
- `exp2_dijkstra_vs_astar.csv`: Graph traversal execution time and node reduction.
- `exp3_breakdown_maut_ranking.csv`: Capacity-aware rescue ranking avoiding seat violations.
- `exp4_gps_sampling_quota.csv`: Quota compliance under varying update frequencies.
- `exp5_attendance_verification.csv`: Cryptographic QR verification with duplicate prevention.

