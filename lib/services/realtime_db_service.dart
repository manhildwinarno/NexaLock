import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Realtime Database service for IoT device communication
class RealtimeDbService {
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://nexalock-8ec96-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  // ─── Door Control ──────────────────────────────────────────────

  /// Stream of door lock status changes (true = locked, false = unlocked)
  Stream<bool> get doorLockStatusStream {
    return _db.child('door/lock_status').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is bool) return value;
      if (value is String) {
        final v = value.toLowerCase().trim();
        // Handle ESP32 string formats: 'locked'/'unlocked', 'true'/'false'
        if (v == 'unlocked' || v == 'false') return false;
        return true; // 'locked', 'true', or any other string = locked
      }
      return true; // Default to locked if unknown
    });
  }

  /// Send a lock/unlock command to the device
  Future<void> sendDoorCommand(String command) async {
    try {
      await _db.child('door').update({
        'command': command,
        'last_updated': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error sending door command: $e');
      rethrow;
    }
  }

  /// Update door metadata after a successful command
  Future<void> updateDoorMetadata({
    required String lastMethod,
    required String lastUser,
  }) async {
    try {
      await _db.child('door').update({
        'last_method': lastMethod,
        'last_user': lastUser,
        'last_updated': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error updating door metadata: $e');
    }
  }

  // ─── RFID Scanner ─────────────────────────────────────────────

  /// Stream of RFID scans (used for card registration)
  Stream<String?> get rfidScanStream {
    return _db.child('rfid/last_scanned_uid').onValue.map((event) {
      final value = event.snapshot.value;
      return value?.toString();
    });
  }

  /// Clear RFID UID after successful registration — write empty string to prevent re-trigger
  Future<void> clearRfidUid() async {
    try {
      await _db.child('rfid/last_scanned_uid').set('');
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error clearing RFID UID: $e');
    }
  }

  /// Register a card UID as allowed in RTDB for ESP32 validation
  Future<void> registerAllowedCard(String rfidUid) async {
    try {
      await _db.child('rfid/allowed_cards/$rfidUid').set(true);
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error registering allowed card: $e');
      rethrow;
    }
  }

  /// Revoke a card UID from RTDB allowed_cards
  Future<void> revokeAllowedCard(String rfidUid) async {
    try {
      await _db.child('rfid/allowed_cards/$rfidUid').remove();
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error revoking allowed card: $e');
      rethrow;
    }
  }

  // ─── Device Status ────────────────────────────────────────────

  /// Stream of device Wi-Fi signal status
  Stream<String> get deviceWifiStream {
    return _db.child('device/wifi').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is String && value.isNotEmpty) return value;
      return 'N/A';
    });
  }

  /// Stream of device battery level
  Stream<String> get deviceBatteryStream {
    return _db.child('device/battery').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is int) return '$value%';
      if (value is String && value.isNotEmpty) {
        return value.contains('%') ? value : '$value%';
      }
      return 'N/A';
    });
  }

  // ─── OTA Firmware ─────────────────────────────────────────────

  /// Write OTA firmware update info
  Future<void> pushOtaUpdate({
    required String firmwareVersion,
    required String firmwareUrl,
  }) async {
    try {
      await _db.child('ota').set({
        'firmware_version': firmwareVersion,
        'firmware_url': firmwareUrl,
        'update_available': true,
      });
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error pushing OTA update: $e');
      rethrow;
    }
  }

  /// Read current OTA status
  Future<Map<String, dynamic>?> getOtaStatus() async {
    try {
      final snapshot = await _db.child('ota').get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[NexaLock RTDB] Error reading OTA status: $e');
      return null;
    }
  }
}
