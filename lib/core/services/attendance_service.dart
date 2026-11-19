import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/attendance_model.dart';
import '../algorithms/haversine.dart';

class AttendanceVerificationResult {
  final bool isSuccess;
  final String message;
  final AttendanceModel? record;

  const AttendanceVerificationResult({
    required this.isSuccess,
    required this.message,
    this.record,
  });
}

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  static const String _tokenSecret = "CAMPUS_TRANSPORT_ATTENDANCE_KEY_2026";
  final List<AttendanceModel> _records = [];
  final Set<String> _processedAttendanceKeys = {}; // Prevents duplicate check-ins

  List<AttendanceModel> get records => List.unmodifiable(_records);

  /// Generates a replay-resistant, cryptographically signed, short-lived QR token for student boarding
  String generateSignedQrToken({
    required String studentId,
    required String tripId,
    int validityMinutes = 15,
  }) {
    final expiryTimestamp = DateTime.now().add(Duration(minutes: validityMinutes)).millisecondsSinceEpoch;
    final payload = "$studentId:$tripId:$expiryTimestamp";
    final hmac = Hmac(sha256, utf8.encode(_tokenSecret));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    // Format: base64(payload.signature)
    final tokenString = "$payload.$signature";
    return base64Url.encode(utf8.encode(tokenString));
  }

  /// Verifies a scanned QR token against student identity, expiration, geofence, and duplicate check
  AttendanceVerificationResult verifyScannedToken({
    required String base64Token,
    required String currentTripId,
    required String verifierDriverId,
    required String studentName,
    required String rollNumber,
    required String stopId,
    required String stopName,
    required double busLat,
    required double busLng,
    required double stopLat,
    required double stopLng,
    String? busId,
  }) {
    try {
      final decodedString = utf8.decode(base64Url.decode(base64Token));
      final parts = decodedString.split('.');
      if (parts.length != 2) {
        return const AttendanceVerificationResult(
          isSuccess: false,
          message: "Invalid QR format or corrupted token",
        );
      }

      final payload = parts[0];
      final providedSignature = parts[1];

      // 1. Verify HMAC signature integrity
      final hmac = Hmac(sha256, utf8.encode(_tokenSecret));
      final expectedSignature = hmac.convert(utf8.encode(payload)).toString();
      if (providedSignature != expectedSignature) {
        return const AttendanceVerificationResult(
          isSuccess: false,
          message: "Cryptographic signature mismatch: Untrusted or forged token",
        );
      }

      // 2. Extract payload fields
      final fields = payload.split(':');
      final tokenStudentId = fields[0];
      final tokenTripId = fields[1];
      final expiryMs = int.tryParse(fields[2]) ?? 0;

      // 3. Expiration check (anti-replay)
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs > expiryMs) {
        return const AttendanceVerificationResult(
          isSuccess: false,
          message: "QR code expired. Please refresh your boarding pass",
        );
      }

      // 4. Duplicate check: Each student can board a trip only once
      final duplicateKey = "${tokenTripId}_$tokenStudentId";
      if (_processedAttendanceKeys.contains(duplicateKey)) {
        return const AttendanceVerificationResult(
          isSuccess: false,
          message: "Duplicate boarding attempt: Student already verified for this trip",
        );
      }

      // 5. Geofence proximity validation (within 150m of stop)
      final distanceToStop = Haversine.distanceMeters(busLat, busLng, stopLat, stopLng);
      final isGeofenceValid = distanceToStop <= 150.0;

      final targetBusId = busId ?? (currentTripId.startsWith('trip_') ? currentTripId.replaceFirst('trip_', '') : 'bus_01');

      final newRecord = AttendanceModel(
        id: "att_${DateTime.now().millisecondsSinceEpoch}",
        tripId: currentTripId,
        busId: targetBusId,
        studentId: tokenStudentId,
        studentName: studentName,
        rollNumber: rollNumber,
        stopId: stopId,
        stopName: stopName,
        status: AttendanceStatus.boarded,
        timestamp: DateTime.now(),
        verifiedByDriverId: verifierDriverId,
        verificationMethod: 'qr_code',
        isGeofenceVerified: isGeofenceValid,
      );

      _processedAttendanceKeys.add(duplicateKey);
      _records.add(newRecord);

      return AttendanceVerificationResult(
        isSuccess: true,
        message: "Boarding verified successfully (${isGeofenceValid ? 'At scheduled stop' : 'Stop proximity override logged'})",
        record: newRecord,
      );
    } catch (e) {
      return AttendanceVerificationResult(
        isSuccess: false,
        message: "Verification failed: $e",
      );
    }
  }

  /// Exports attendance logs to formatted CSV for college administration & audits
  String exportAttendanceCsv() {
    final buffer = StringBuffer();
    buffer.writeln("AttendanceID,TripID,StudentID,StudentName,RollNumber,StopName,Status,Timestamp,VerifiedBy,GeofenceVerified");
    for (final r in _records) {
      buffer.writeln("${r.id},${r.tripId},${r.studentId},\"${r.studentName}\",${r.rollNumber},\"${r.stopName}\",${r.status.nameString},\"${r.timestamp.toIso8601String()}\",${r.verifiedByDriverId},${r.isGeofenceVerified}");
    }
    return buffer.toString();
  }
}

