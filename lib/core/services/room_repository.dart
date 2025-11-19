import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';
// Import the notification helper file
import 'package:beehive/features/teachers/notify_students.dart'; 
// Import the full service to pass to the notification helper
import 'package:beehive/core/services/firestore_services.dart'; 

class RoomRepository {
  final FirebaseFirestore _db;
  RoomRepository(this._db);

  // --- HELPER 1: Get Teacher Full Name (Used by unarchiveRoom) ---
  Future<String> _getTeacherFullName(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final firstName = userData?['firstName'] ?? '';
        final lastName = userData?['lastName'] ?? '';
        return '$firstName $lastName';
      }
    } catch (e) {
      print('Error fetching teacher name for ID $userId: $e');
    }
    return userId; 
  }
  // ----------------------------------------

  // Helper function to get necessary room data for the notification
  Future<RoomModel?> _getRoomDetails(String roomId) async {
    final doc = await _db.collection('rooms').doc(roomId).get();
    if (doc.exists) {
      return RoomModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  // --- RESTORED METHOD ---
  Stream<List<RoomModel>> getRoomsStream(List<String> roomIds) {
    if (roomIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('rooms')
        .where(FieldPath.documentId, whereIn: roomIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }
  // -------------------------

  Stream<List<RoomModel>> getTeacherRoomsStream(String teacherUid) {
    return _db
        .collection('rooms')
        .where('creatorId', isEqualTo: teacherUid)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  Stream<List<RoomModel>> getArchivedTeacherRoomsStream(String teacherUid) {
    return _db
        .collection('rooms')
        .where('creatorId', isEqualTo: teacherUid)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  Future<List<RoomModel>> getTeacherRooms(String teacherUid) async {
    try {
      final snapshot = await _db
          .collection('rooms')
          .where('creatorId', isEqualTo: teacherUid)
          .where('isArchived', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting teacher rooms: $e');
      return [];
    }
  }

  Future<void> archiveRoom(String roomId) async {
    try {
      await _db.collection('rooms').doc(roomId).update({
        'isArchived': true, 
        'archivedAt': FieldValue.serverTimestamp(), 
      });

      final membersSnapshot = await _db.collection('rooms').doc(roomId).collection('members').get();
      final batch = _db.batch();

      for (var memberDoc in membersSnapshot.docs) {
        String studentId = memberDoc.id;
        final joinedRoomRef = _db
            .collection('users')
            .doc(studentId)
            .collection('joinedRooms')
            .doc(roomId);

        batch.update(joinedRoomRef, {
          'isArchived': true,
        });
      }
      await batch.commit(); 
      
    } catch (e) {
      print('Error archiving room: $e');
      rethrow;
    }
  }

  // FINAL CORRECTED METHOD: Unarchives room and sends notifications
  Future<void> unarchiveRoom(String roomId) async {
    try {
      // FIX: Called the zero-argument constructor for FirestoreService
      final firestoreService = FirestoreService(); 
      
      // 1. Get room details
      final room = await _getRoomDetails(roomId);
      if (room == null) {
          throw Exception('Room not found');
      }
      
      // 2. FETCH FULL NAME (Fixes the email appearing in notification)
      final teacherName = await _getTeacherFullName(room.createdBy);
      
      // 3. Update main room doc
      await _db.collection('rooms').doc(roomId).update({
        'isArchived': false, 
      });

      // 4. Update student joinedRooms 
      final membersSnapshot = await _db.collection('rooms').doc(roomId).collection('members').get();
      final studentIds = membersSnapshot.docs.map((doc) => doc.id).toList();

      final batch = _db.batch();
      for (var memberId in studentIds) {
          final userRoomRef = _db.collection('users').doc(memberId).collection('joinedRooms').doc(roomId);
          batch.update(userRoomRef, {'isArchived': false}); 
      }
      await batch.commit();

      // 5. Send Notification using helper
      await notifyStudentsOnRoomUnarchive( 
          className: room.className,
          subject: room.subject,
          roomId: roomId,
          teacherName: teacherName, // Passing the fetched full name
          firestoreService: firestoreService, // Passing the service instance
      );

    } catch (e) {
      print('Error unarchiving room: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final membersSnapshot =
          await _db.collection('rooms').doc(roomId).collection('members').get();
      final modulesSnapshot =
          await _db.collection('rooms').doc(roomId).collection('modules').get();
      final batch = _db.batch();

      for (var memberDoc in membersSnapshot.docs) {
        String studentId = memberDoc.id;
        batch.delete(memberDoc.reference);
        final joinedRoomRef = _db
            .collection('users')
            .doc(studentId)
            .collection('joinedRooms')
            .doc(roomId);
        batch.delete(joinedRoomRef);
      }

      for (var moduleDoc in modulesSnapshot.docs) {
        batch.delete(moduleDoc.reference);
      }

      batch.delete(_db.collection('rooms').doc(roomId));
      await batch.commit();
    } catch (e) {
      print('Error deleting room: $e');
      rethrow;
    }
  }

  Future<bool> checkRoomExists(String roomCode) async {
    try {
      final doc = await _db.collection('rooms').doc(roomCode).get();
      return doc.exists;
    } catch (e) {
      print('Error checking room existence: $e');
      return false;
    }
  }

  Future<void> joinRoom(String roomCode, UserModel user) async {
    try {
      final batch = _db.batch();
      final roomMemberRef =
          _db.collection('rooms').doc(roomCode).collection('members').doc(user.uid);
      batch.set(roomMemberRef, {
        'email': user.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      final userRoomRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('joinedRooms')
          .doc(roomCode);
      
      batch.set(userRoomRef, {
        'roomId': roomCode,
        'joinedAt': FieldValue.serverTimestamp(),
        'isArchived': false, 
      });

      await batch.commit();
    } catch (e) {
      print('Error joining room: $e');
      rethrow;
    }
  }

  Future<void> createRoom(RoomModel room) async {
    try {
      final roomMap = room.toJson();
      roomMap['createdAt'] = FieldValue.serverTimestamp();
      roomMap['isArchived'] = false; 
      await _db.collection('rooms').doc(room.id).set(roomMap);
    } catch (e) {
      print('Error creating room: $e');
      rethrow;
    }
  }

  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final doc = await _db.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return RoomModel.fromFirestore(
            doc);
      }
    } catch (e) {
      print('Error getting room: $e');
    }
    return null;
  }

  Future<List<String>> getRoomMemberIds(String roomId) async {
    try {
      final snapshot = await _db
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting room members: $e');
      return [];
    }
  }
}