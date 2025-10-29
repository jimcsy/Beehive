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

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(code)
          .collection('members')
          .doc(user!.uid)
          .set({
        'email': user!.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });

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
      backgroundColor: Colors.white,
      // 1. Title from "Join Room", style from "Delete Room"
      title: const Text(
        'Join Room',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      // 2. Content is the TextField
      content: SizedBox(
        height: 50,
        child: TextField(
          controller: codeController,
          style: const TextStyle(fontSize: 12),
          cursorColor: Color(0xFF443C36),
          decoration: InputDecoration(
            labelText: "Enter Room Code",
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF443C36).withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
          ),
        ),
      ),
      // 3. Actions use the styled two-button layout
      actions: [
        Row(
          children: [
            // "Cancel" button, styled like "No"
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), // Just pops
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFFA27221)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  // --- ADD THIS LINE ---
                  // This makes the button fill the width of the Expanded
                  minimumSize:
                      MaterialStateProperty.all(const Size(double.infinity, 40)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            // "Join" button, styled like "Yes"
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: isLoading ? null : joinRoom,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 235, 200, 95)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  // --- ADD THIS LINE ---
                  // This makes the button fill the width of the Expanded
                  minimumSize:
                      MaterialStateProperty.all(const Size(double.infinity, 40)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                // Show loading indicator or text
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

