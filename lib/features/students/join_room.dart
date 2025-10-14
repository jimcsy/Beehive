import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinRoomDialog extends StatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final TextEditingController codeController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  Future<void> joinRoom() async {
    final code = codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(code)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room not found!")),
        );
        setState(() => isLoading = false);
        return;
      }

      // 🔹 Add the student under a "members" subcollection
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(code)
          .collection('members')
          .doc(user!.uid)
          .set({
        'email': user!.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Optionally, also save joined rooms under the student’s profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('joinedRooms')
          .doc(code)
          .set({
        'roomId': code,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Joined room successfully!")),
      );
    } catch (e) {
      debugPrint("Error joining room: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Join Room"),
      content: TextField(
        controller: codeController,
        decoration: const InputDecoration(
          labelText: "Enter Room Code",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : joinRoom,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Join"),
        ),
      ],
    );
  }
}
