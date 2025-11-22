import 'package:beehive/core/services/firestore_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for direct query

class JoinRoomDialog extends StatefulWidget {
  final UserModel userModel;
  const JoinRoomDialog({super.key, required this.userModel});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  Future<void> joinRoom() async {
    final code = codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => isLoading = true);

    // Get the service from Provider
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      // 1. Check if the room exists AND get its ID
      final roomQuery = await FirebaseFirestore.instance
          .collection('rooms')
          .where('roomCode', isEqualTo: code)
          .limit(1)
          .get();

      if (roomQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Room not found!")),
          );
        }
      } else {
        // 🌟 FOUND THE ROOM ID 🌟
        final roomId = roomQuery.docs.first.id;

        // 2. Join the room (Standard Logic)
        await firestoreService.rooms.joinRoom(code, widget.userModel);

        // 3. 🌟 GENERATE PROGRESS 🌟
        // This creates the document in users/{uid}/progress/{moduleId}
        await firestoreService.users.initializeProgressForRoom(
            widget.userModel.uid, 
            roomId
        );

        if (mounted) {
          Navigator.pop(context); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Joined room successfully!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error joining room: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to join room.")),
        );
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Join Room',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        height: 50,
        child: TextField(
          controller: codeController,
          style: const TextStyle(fontSize: 12),
          cursorColor: const Color(0xFF443C36),
          decoration: InputDecoration(
            labelText: "Enter Room Code",
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF443C36).withOpacity(0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFFA27221)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  minimumSize:
                      MaterialStateProperty.all(const Size(double.infinity, 40)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                child: const Text('No'),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: isLoading ? null : joinRoom,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 235, 200, 95)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  minimumSize:
                      MaterialStateProperty.all(const Size(double.infinity, 40)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
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