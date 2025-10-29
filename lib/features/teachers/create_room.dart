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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.10),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75, 
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), 
                topRight: Radius.circular(20), 
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24),
                      ),
                      const Text(
                        'Create Class',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
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
                          // Keep existing Firebase logic
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            showMessage(context, "You must be logged in to create a room."); 
                            return;
                          }

                          final email = user.email ?? 'unknown';
                          final uid = user.uid;
                          final roomCode = _generateRoomCode(6);
                          final roomLink =
                              "https://beehiveapp.page.link/$roomCode";

                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomCode)
                              .set({
                            'className': className,
                            'section': section,
                            'subject': subject,
                            'roomCode': roomCode,
                            'roomLink': roomLink,
                            'createdBy': email,
                            'creatorId': uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          setState(() => roomCreated = true);
                        },
                        child: Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form fields
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: classNameController,
                          label: 'Class name',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: sectionController,
                          label: 'Section',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: subjectController,
                          label: 'Subject',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(
          color: Colors.grey[600], 
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: Colors.black, 
          fontSize: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide(
            color: Colors.grey[400]!, // Light grey border
            width: 1,
          ),
        ),
        // Focused border style
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: const BorderSide(
            color: Colors.black, // Darker border when focused
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 16),
        isDense: true, 
      ),
      style: const TextStyle(
          fontSize: 16, color: Colors.black), 
    );
  }

 String _generateRoomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
