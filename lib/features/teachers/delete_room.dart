import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteRoom({
  required BuildContext context,
  required String roomCode,
  required String className,
}) async {
  try {
    // Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete "$className"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // If confirmed, proceed with deletion
    if (confirm ?? false) {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);

      // Delete all subcollections (like members)
      final membersSnapshot = await roomRef.collection('members').get();
      for (var doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete main room document
      await roomRef.delete();

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room "$className" deleted successfully')),
      );
    }
  } catch (e) {
    // Show error message if failed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete room')),
    );
    debugPrint('❌ Delete room error: $e');
  }
}
