import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('Users');
  CollectionReference<Map<String, dynamic>> get _logsRef => _db.collection('Access_Logs');

  static bool isOffline = false;

  /// Fetch user profile by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        isOffline = false;
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      isOffline = true;
      debugPrint('[NexaLock Firestore] Backend unreachable/offline. Using cached permissions.');
      return null;
    }
  }

  /// Stream user profile by UID
  Stream<UserModel?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Stream all users for name mapping
  Stream<List<UserModel>> getAllUsersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data(), doc.id)).toList();
    });
  }

  /// Create or update user profile
  Future<void> saveUser(UserModel user) async {
    if (isOffline) return; // Short-circuit if database is offline to save 3s timeout
    try {
      await _usersRef
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      isOffline = true;
      debugPrint('[NexaLock Firestore] Local write saved to cache (offline mode).');
    }
  }

  /// Log access attempt
  Future<void> logAccess({
    String? uid,
    required String userName,
    required String method,
    required String status,
  }) async {
    if (isOffline) return; // Short-circuit if database is offline to save 2s timeout
    try {
      await _logsRef.add({
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'user_name': userName,
        'method': method,
        'status': status,
      }).timeout(const Duration(seconds: 2));
    } catch (e) {
      isOffline = true;
      debugPrint('[NexaLock Firestore] Access log cached locally.');
    }
  }
  /// Delete a specific history log entry
  Future<void> deleteHistoryEntry(String docId) async {
    try {
      await _logsRef.doc(docId).delete().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[NexaLock Firestore] Error deleting history entry: $e');
      rethrow;
    }
  }

  /// Delete all history log entries based on role
  Future<void> deleteAllHistory(String role, String userId) async {
    try {
      Query<Map<String, dynamic>> query = _logsRef;
      if (role != 'admin') {
        query = query.where('uid', isEqualTo: userId);
      }
      
      // Firestore batches are limited to 500 operations
      final snapshots = await query.limit(500).get();
      final batch = _db.batch();
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('[NexaLock Firestore] Error deleting all history: $e');
      rethrow;
    }
  }
}
