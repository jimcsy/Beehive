// Conceptual File: lib/features/teachers/notify_students.dart

import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/core/services/user_repository.dart'; // REQUIRED for Unarchive logic

// This class will be instantiated inside RoomRepository's methods.

// Helper to get RoomMemberIds (This should typically live in RoomRepository, 
// but we define a function here to use the correct repository calls).
// NOTE: RoomRepository has the getRoomMemberIds method, so we will use that 
// via the firestoreService.rooms reference.

// --- 1. NOTIFY STUDENTS ON ROOM DELETE ---
Future<void> notifyStudentsOnRoomDelete({
  required String className,
  required String subject,
  required String roomId,
  required String teacherName,
  required FirestoreService firestoreService,
}) async {
  try {
    print("🔍 Finding students who joined room: $roomId for deletion.");

    // Use the service to get member IDs (method is in RoomRepository)
    final studentIds = await firestoreService.rooms.getRoomMemberIds(roomId);

    if (studentIds.isEmpty) {
      print("⚠️ No students found for room $roomId. Skipping deletion notifications.");
      return;
    }

    print("✅ Found ${studentIds.length} students to notify about deletion.");

    // Use the UserRepository to send batch writes
    await firestoreService.users.sendRoomDeletionNotifications(
      roomId: roomId,
      className: className,
      subject: subject,
      teacherName: teacherName,
      studentIds: studentIds,
    );

    print("✅ Deletion notification process completed!");
  } catch (e) {
    print("❌ Error sending deletion notifications: $e");
    rethrow;
  }
}


// --- 2. NOTIFY STUDENTS ON ROOM ARCHIVE ---
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
    rethrow;
  }
}

// --- 3. NOTIFY STUDENTS ON ROOM UNARCHIVE (CORRECTED) ---
// This is the functional version of the method.
Future<void> notifyStudentsOnRoomUnarchive({
  required String className,
  required String subject,
  required String roomId,
  required String teacherName,
  // 🛑 FIX: This requires the full service to perform both lookup (rooms) and write (users)
  required FirestoreService firestoreService, 
}) async {
  try {
    print("🔍 Finding students who joined room: $roomId for unarchive notification.");

    // 1. Get the list of student IDs who are members of this room (via RoomRepository)
    final studentIds = await firestoreService.rooms.getRoomMemberIds(roomId);

    if (studentIds.isEmpty) {
      print("⚠️ No students found for room $roomId. Skipping unarchive notifications.");
      return;
    }

    print("✅ Found ${studentIds.length} students to notify about unarchive.");

    // 2. Use the service to send the batch unarchive notifications (via UserRepository)
    await firestoreService.users.sendRoomUnarchiveNotifications(
      roomId: roomId,
      className: className,
      subject: subject,
      teacherName: teacherName,
      studentIds: studentIds,
    );

    print("✅ Unarchive notification process completed!");
  } catch (e) {
    print("❌ Error sending unarchive notifications: $e");
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