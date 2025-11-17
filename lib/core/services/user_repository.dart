import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/recent_module.dart';

// Reference to the collection the Cloud Function listens to
final CollectionReference _outboundCollection = 
    FirebaseFirestore.instance.collection('outboundNotifications');

class UserRepository {
  final FirebaseFirestore _db;
  UserRepository(this._db);

  // --- NEW METHOD: Updates the FCM token for the user ---
  Future<void> updateFCMToken(String uid, String? token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': token, // Store the device token
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

  // UPDATED: Writes to outboundNotifications collection for FCM trigger
  Future<void> sendRoomDeletionNotifications({
    required String roomId,
    required String className,
    required String subject,
    required String teacherName,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    
    // Message payload that the Cloud Function will read
    final notificationPayload = {
      'title': 'Room Deleted',
      'message': 'The room "$className" ($subject) has been deleted by $teacherName.',
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'room_deletion',
      'roomId': roomId,
      'read': false,
    };

    for (String studentId in studentIds) {
      // Write a notification document for each student to the outbound collection
      batch.set(_outboundCollection.doc(), {
        ...notificationPayload, // Spread the common payload
        'recipientId': studentId, // CRITICAL: Target the specific student
      });
    }
    await batch.commit();
  }
  
  // UPDATED: Writes to outboundNotifications collection for FCM trigger
  Future<void> sendRoomArchiveNotifications({
    required String roomId,
    required String className,
    required String subject,
    required String teacherName,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    
    // Message payload that the Cloud Function will read
    final notificationPayload = {
      'title': 'Room Archived',
      'message':
          '⚠️ Room Archive Alert: The course "$className" ($subject) has been archived by $teacherName. It is no longer visible in your active list.',
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'room_archive',
      'roomId': roomId,
      'read': false,
    };

    for (String studentId in studentIds) {
      // Write a notification document for each student to the outbound collection
      batch.set(_outboundCollection.doc(), {
        ...notificationPayload, // Spread the common payload
        'recipientId': studentId, // CRITICAL: Target the specific student
      });
    }
    await batch.commit();
  }

  // UPDATED: Writes to outboundNotifications collection for FCM trigger
  Future<void> sendTestNotification(String studentId) async {
    final notificationPayload = {
      'recipientId': studentId,
      'title': '🧪 Test Notification',
      'message': 'This is a test notification to check if the system is working!',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'test',
    };
    
    await _outboundCollection.add(notificationPayload);
  }
}