import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/recent_module.dart';

class UserRepository {
  final FirebaseFirestore _db;
  UserRepository(this._db);

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
    return _db
        .collection('users')
        .doc(uid)
        .collection('joinedRooms')
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            return doc.id; 
          })
          .toList();
    });
  }

  // --- 🌟 NEW METHOD: INITIALIZE PROGRESS WHEN JOINING ROOM 🌟 ---
  Future<void> initializeProgressForRoom(String uid, String roomId) async {
    try {
      final roomModulesSnapshot = await _db
          .collection('rooms')
          .doc(roomId)
          .collection('modules')
          .get();

      if (roomModulesSnapshot.docs.isEmpty) return;

      final batch = _db.batch();

      for (var moduleDoc in roomModulesSnapshot.docs) {
        final moduleId = moduleDoc.id;
        
        // 🌟 FIX: Create a Composite ID (RoomID_ModuleID)
        final uniqueProgressId = '${roomId}_$moduleId';

        final progressRef = _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(uniqueProgressId); // <--- USING UNIQUE ID HERE
            
        final progressSnap = await progressRef.get();
        if (progressSnap.exists) continue; 

        // ... rest of the logic remains the same ...
        final lessonsSnapshot = await _db
            .collection('modules')
            .doc(moduleId)
            .collection('lessons')
            .get();

        final Map<String, bool> lessonsMap = {};
        for (var lesson in lessonsSnapshot.docs) {
          lessonsMap[lesson.id] = false; 
        }

        final progressData = {
          'moduleId': moduleId,
          'roomId': roomId, 
          'completed': false,
          'lessons': lessonsMap,
          'startedAt': FieldValue.serverTimestamp(),
        };

        batch.set(progressRef, progressData);
      }

      await batch.commit();
      print("✅ Progress initialized for room $roomId with unique IDs");

    } catch (e) {
      print("❌ Error initializing progress: $e");
    }
  }
  // ---------------------------------------------------------------

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