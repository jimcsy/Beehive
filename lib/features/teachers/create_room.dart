import 'package:beehive/features/utils/show_modal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CreateRoom extends StatefulWidget {
  const CreateRoom({super.key});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  bool roomCreated = false;

  final TextEditingController classNameController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!roomCreated)
              GestureDetector(
                onTap: () => _showCreateRoomDialog(context),
                child: Row(
                  children: [
                    Icon(Icons.meeting_room, color: Colors.blue),
                    const SizedBox(width: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Create a room",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            //can delete
            if (roomCreated)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Room created successfully!",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟨 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Create Room",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🧾 TextFields
                  TextField(
                    controller: classNameController,
                    decoration: const InputDecoration(
                      labelText: 'Class Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Create button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final className = classNameController.text.trim();
                          final section = sectionController.text.trim();
                          final subject = subjectController.text.trim();

                          if (className.isEmpty ||
                              section.isEmpty ||
                              subject.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill out all fields.'),
                              ),
                            );
                            return;
                          }

                          // 🔑 Get current user
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            showMessage(context, "You must be logged in to create a room.");
                            return;
                          }

                          final email = user.email ?? 'unknown';
                          final uid = user.uid;

                          // 🔢 Generate random room code
                          final roomCode = _generateRoomCode(6);
                          final roomLink =
                              "https://beehiveapp.page.link/$roomCode";

                          // 🧩 Save to Firestore
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomCode)
                              .set({
                            'className': className,
                            'section': section,
                            'subject': subject,
                            'roomCode': roomCode,
                            'roomLink': roomLink,
                            'createdBy': email, // 👈 save email
                            'creatorId': uid, // 👈 optional: Firebase UID
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // ✅ Close dialog + hide button
                          Navigator.pop(context);
                          setState(() => roomCreated = true);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _generateRoomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
