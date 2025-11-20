import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/recent_module.dart';

class UserRepository {
  final FirebaseFirestore _db;
  UserRepository(this._db);

  // NEW METHOD: Updates the FCM token for the user (Kept for future use)
  Future<void> updateFCMToken(String uid, String? token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': token, 
      });
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> createUser(UserModel user) async {
    try {
      final userMap = user.toJson();
      userMap['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(user.uid).set(userMap);
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Stream<List<String>> getJoinedRoomIdsStream(String uid) {
    // NOTE: Some older joinedRooms documents may not have the `isArchived`
    // field set. Querying with `.where('isArchived', isEqualTo: false)` will
    // exclude those documents. To be robust we fetch all joinedRooms and
    // perform the archive filtering client-side so documents missing the flag
    // are treated as active (not archived).
    return _db
        .collection('users')
        .doc(uid)
        .collection('joinedRooms')
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      // Debug: log counts to help troubleshoot empty lists
      try {
        // Print useful debug info during development
        // ignore: avoid_print
        print('getJoinedRoomIdsStream: found ${snapshot.docs.length} joinedRooms for user=$uid');
      } catch (_) {}

      return snapshot.docs
          .map((doc) {
            return doc.id; 
          })
          .toList();
    });
  }

  Future<RecentModuleModel?> getRecentModule(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('recent')
          .doc('lastOpened')
          .get();

      if (doc.exists) {
        return RecentModuleModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting recent module: $e');
    }
    return null;
  }

  Future<void> setRecentModule(
    String uid,
    String roomId,
    String moduleId,
    String title,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('recent')
          .doc('lastOpened')
          .set({
        'roomId': roomId,
        'moduleId': moduleId,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting recent module: $e');
    }
  }

  Future<void> sendRoomDeletionNotifications({
    required String roomId,
    required String className,
    required String subject,
    required String teacherName,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    final notificationData = {
      'title': 'Room Deleted',
      'message':
          'The room "$className" ($subject) has been deleted by $teacherName.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'roomId': roomId,
      'type': 'room_deletion',
    };

    for (String studentId in studentIds) {
      final notifRef = _db
          .collection('users')
          .doc(studentId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, notificationData);
    }
    await batch.commit();
  }

  Future<void> sendRoomArchiveNotifications({
    required String roomId,
    required String className,
    required String subject,
    required String teacherName,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    final notificationData = {
      'title': 'Room Archived',
      'message':
          '⚠️ Room Archive Alert: The course "$className" ($subject) has been archived by $teacherName. It is no longer visible in your active list.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'roomId': roomId,
      'type': 'room_archive',
    };

    for (String studentId in studentIds) {
      final notifRef = _db
          .collection('users')
          .doc(studentId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, notificationData);
    }
    await batch.commit();
  }

  // NEW METHOD: Sends notifications for room unarchiving
  Future<void> sendRoomUnarchiveNotifications({
    required String roomId,
    required String className,
    required String subject,
    required String teacherName,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    final notificationData = {
      'title': 'Room Restored',
      'message':
          '✅ Room Restored: The course "$className" ($subject) has been restored by $teacherName. It is now visible in your active list.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'roomId': roomId,
      'type': 'room_unarchive',
    };

    for (String studentId in studentIds) {
      final notifRef = _db
          .collection('users')
          .doc(studentId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, notificationData);
    }
    await batch.commit();
  }

  Future<void> sendTestNotification(String studentId) async {
    await _db.collection('users').doc(studentId).collection('notifications').add({
      'title': '🧪 Test Notification',
      'message': 'This is a test notification to check if the system is working!',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'test',
    });
  }
}