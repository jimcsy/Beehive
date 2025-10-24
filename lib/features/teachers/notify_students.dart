import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> notifyStudentsOnRoomDelete({
  required String className,
  required String subject,
  required String roomId,
  required String teacherName,
}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    print("🔍 Finding students who joined room: $roomId");

    // 🔹 First method: Check room members subcollection
    final roomMembersSnapshot = await firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .get();

    List<String> studentIds = [];
    
    // Get student IDs from room members
    for (var memberDoc in roomMembersSnapshot.docs) {
      studentIds.add(memberDoc.id); // member doc ID is the student ID
      print("🔍 Found member: ${memberDoc.id}");
    }

    // 🔹 Second method: Search all users' joinedRooms subcollections
    if (studentIds.isEmpty) {
      print("🔍 No members found in room subcollection. Searching user subcollections...");
      
      final usersSnapshot = await firestore.collection('users').get();
      
      for (var userDoc in usersSnapshot.docs) {
        final joinedRoomsSnapshot = await userDoc.reference
            .collection('joinedRooms')
            .where('roomId', isEqualTo: roomId)
            .get();
            
        if (joinedRoomsSnapshot.docs.isNotEmpty) {
          studentIds.add(userDoc.id);
          print("🔍 Found student in joinedRooms: ${userDoc.id}");
        }
      }
    }

    if (studentIds.isEmpty) {
      print("⚠️ No students found for room $roomId. Skipping notifications.");
      return;
    }

    print("✅ Found ${studentIds.length} students to notify.");

    // 🔹 Send notifications to all found students
    for (String studentId in studentIds) {
      try {
        // Get student email for better notification
        final userDoc = await firestore.collection('users').doc(studentId).get();
        final studentEmail = userDoc.data()?['email'] ?? 'Unknown';

        // 🔹 Save notification inside each student's subcollection
        await firestore
            .collection('users')
            .doc(studentId)
            .collection('notifications')
            .add({
          'title': 'Room Deleted',
          'message': 'The room "$className" ($subject) has been deleted by $teacherName.',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false, // Use 'read' instead of 'isRead' for consistency
          'roomId': roomId,
          'type': 'room_deletion',
        });

        // 🔹 Clean up: Remove the room from student's joinedRooms subcollection
        final joinedRoomsSnapshot = await firestore
            .collection('users')
            .doc(studentId)
            .collection('joinedRooms')
            .where('roomId', isEqualTo: roomId)
            .get();
            
        for (var joinedRoomDoc in joinedRoomsSnapshot.docs) {
          await joinedRoomDoc.reference.delete();
          print("🧹 Cleaned up joinedRoom for $studentEmail");
        }

        print("📩 Notification sent to $studentEmail ($studentId)");
      } catch (notifError) {
        print("❌ Failed to send notification to $studentId: $notifError");
      }
    }

    print("✅ Notification process completed!");
  } catch (e) {
    print("❌ Error sending notifications: $e");
  }
}

// 🧪 TEST FUNCTION - Call this to test notifications manually
Future<void> sendTestNotification({required String studentId}) async {
  try {
    print("🧪 Sending test notification to student: $studentId");
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .collection('notifications')
        .add({
      'title': '🧪 Test Notification',
      'message': 'This is a test notification to check if the system is working!',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'test',
    });
    
    print("✅ Test notification sent successfully!");
  } catch (e) {
    print("❌ Failed to send test notification: $e");
  }
}
