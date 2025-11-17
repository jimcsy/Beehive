// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED
import 'package:beehive/core/services/firestore_services.dart'; // <-- 2. ADD THIS

Future<void> notifyStudentsOnRoomDelete({
  required String className,
  required String subject,
  required String roomId,
  required String teacherName,
  // --- 3. IT NOW REQUIRES THE SERVICE ---
  required FirestoreService firestoreService,
}) async {
  try {
    print("🔍 Finding students who joined room: $roomId");

    // --- 4. REFACTORED: Use the service ---
    // This is now ONE simple, fast call.
    final studentIds = await firestoreService.rooms.getRoomMemberIds(roomId);

    // --- 5. REMOVED: The entire inefficient fallback logic ---
    // (We no longer query all users)

    if (studentIds.isEmpty) {
      print("⚠️ No students found for room $roomId. Skipping notifications.");
      return;
    }

    print("✅ Found ${studentIds.length} students to notify.");

    // --- 6. REFACTORED: Use the service for batch writes ---
    await firestoreService.users.sendRoomDeletionNotifications(
      roomId: roomId,
      className: className,
      subject: subject,
      teacherName: teacherName,
      studentIds: studentIds,
    );

    print("✅ Notification process completed!");
  } catch (e) {
    print("❌ Error sending notifications: $e");
    // Re-throw the error so the UI can show a message
    rethrow;
  }
}

// 🧪 TEST FUNCTION - Refactored
Future<void> sendTestNotification({
  required String studentId,
  required FirestoreService firestoreService, // <-- Also needs the service
}) async {
  try {
    print("🧪 Sending test notification to student: $studentId");
    
    // --- 7. REFACTORED: Use the service ---
    await firestoreService.users.sendTestNotification(studentId);
    
    print("✅ Test notification sent successfully!");
  } catch (e) {
    print("❌ Failed to send test notification: $e");
  }
}

Future<void> notifyStudentsOnRoomArchive({
  required String className,
  required String subject,
  required String roomId,
  required String teacherName,
  required FirestoreService firestoreService,
}) async {
  try {
    print("🔍 Finding students who joined room: $roomId for archive notification.");

    // 1. Get the list of student IDs who are members of this room
    final studentIds = await firestoreService.rooms.getRoomMemberIds(roomId);

    if (studentIds.isEmpty) {
      print("⚠️ No students found for room $roomId. Skipping archive notifications.");
      return;
    }

    print("✅ Found ${studentIds.length} students to notify about archive.");

    // 2. Use the service to send the batch archive notifications
    await firestoreService.users.sendRoomArchiveNotifications(
      roomId: roomId,
      className: className,
      subject: subject,
      teacherName: teacherName,
      studentIds: studentIds,
    );

    print("✅ Archive notification process completed!");
  } catch (e) {
    print("❌ Error sending archive notifications: $e");
    // Re-throw the error so the UI can show a message
    rethrow;
  }
}