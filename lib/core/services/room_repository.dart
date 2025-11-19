import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';

class RoomRepository {
  final FirebaseFirestore _db;
  RoomRepository(this._db);

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
          .map((doc) => RoomModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // UPDATED: Filtered to exclude archived rooms (isArchived: false)
  Stream<List<RoomModel>> getTeacherRoomsStream(String teacherUid) {
    // NOTE: Some existing room documents may not include `isArchived`.
    // Querying with `.where('isArchived', isEqualTo: false)` will exclude
    // documents that simply lack the field. To support older data we fetch
    // all rooms for the teacher and filter client-side by `isArchived != true`.
    return _db
        .collection('rooms')
        .where('creatorId', isEqualTo: teacherUid)
        .snapshots()
        .map((snapshot) {
      // Filter on the raw document data so we can support documents that
      // don't include the `isArchived` field (treat missing as not archived).
      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isArchived'] != true;
      }).toList();

      return activeDocs
          .map((doc) => RoomModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // NEW METHOD: Gets rooms where the 'isArchived' flag is TRUE
  Stream<List<RoomModel>> getArchivedTeacherRoomsStream(String teacherUid) {
    return _db
        .collection('rooms')
        .where('creatorId', isEqualTo: teacherUid)
        .where('isArchived', isEqualTo: true) // Filter for only archived rooms
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  Future<List<RoomModel>> getTeacherRooms(String teacherUid) async {
    try {
        final snapshot = await _db
          .collection('rooms')
          .where('creatorId', isEqualTo: teacherUid)
          .get();
        // Filter client-side: treat missing `isArchived` as not archived
        final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isArchived'] != true;
        }).toList();

        return activeDocs
          .map((doc) => RoomModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting teacher rooms: $e');
      return [];
    }
  }

  // NEW METHOD: Archives a room
  // Conceptual File: RoomRepository.dart
Future<void> archiveRoom(String roomId) async {
  try {
    // 1. Update the Room document status
    await _db.collection('rooms').doc(roomId).update({
      'isArchived': true, 
      'archivedAt': FieldValue.serverTimestamp(), 
    });

    // 2. CRITICAL STEP: Update the status in the joinedRooms sub-collection
    // Find all students who joined the room
    final membersSnapshot = await _db.collection('rooms').doc(roomId).collection('members').get();
    final batch = _db.batch();

    for (var memberDoc in membersSnapshot.docs) {
      String studentId = memberDoc.id;
      final joinedRoomRef = _db
          .collection('users')
          .doc(studentId)
          .collection('joinedRooms')
          .doc(roomId);

      // Set the archive status in the student's joinedRooms document
      batch.update(joinedRoomRef, {
        'isArchived': true,
      });
    }
    await batch.commit(); // Commit the batch updates
    
  } catch (e) {
    print('Error archiving room: $e');
    rethrow;
  }
}

  // NEW METHOD: Unarchives a room
  Future<void> unarchiveRoom(String roomId) async {
    try {
      // 1) Update the room document
      await _db.collection('rooms').doc(roomId).update({
        'isArchived': false, // Set the flag back to false
        'unarchivedAt': FieldValue.serverTimestamp(),
      });

      // 2) Update all students' joinedRooms sub-documents so the room
      // reappears in their active lists. Older joinedRooms entries may have
      // been set to isArchived=true during archiving.
      final membersSnapshot = await _db.collection('rooms').doc(roomId).collection('members').get();
      if (membersSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var memberDoc in membersSnapshot.docs) {
          final studentId = memberDoc.id;
          final joinedRoomRef = _db
              .collection('users')
              .doc(studentId)
              .collection('joinedRooms')
              .doc(roomId);

          // Use set with merge to avoid overwriting unexpected fields
          batch.set(joinedRoomRef, {'isArchived': false}, SetOptions(merge: true));
        }
        await batch.commit();
      }
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
      
      // 🛑 FIX 2: Add isArchived: false flag to the student's joinedRooms document
      batch.set(userRoomRef, {
        'roomId': roomCode,
        'joinedAt': FieldValue.serverTimestamp(),
        'isArchived': false, // <--- CRITICAL: Initialize status here
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
      roomMap['isArchived'] = false; // Initialize the archive state
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