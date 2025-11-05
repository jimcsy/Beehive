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

  Stream<List<RoomModel>> getTeacherRoomsStream(String teacherUid) {
    return _db
        .collection('rooms')
        .where('creatorId', isEqualTo: teacherUid)
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
      return snapshot.docs
          .map((doc) => RoomModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting teacher rooms: $e');
      return [];
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