import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/shared/show_modal.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED
// import 'package:firebase_auth/firebase_auth.dart'; // <-- 2. NO LONGER NEEDED
import 'dart:math';

// --- 3. ADD IMPORTS ---
import 'package:provider/provider.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';

class CreateRoom extends StatefulWidget {
  // --- 4. ACCEPT THE USER MODEL ---
  final UserModel userModel;
  const CreateRoom({super.key, required this.userModel});

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
      // ... (Your build method's UI is unchanged) ...
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
  
  // --- 5. REFACTORED DIALOG METHOD ---
  void _showCreateRoomDialog(BuildContext context) {
    // Get the service *before* showing the dialog
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.10),
          child: Container(
            // ... (Your container/column/header UI is unchanged) ...
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
                        // --- 6. REFACTORED onPressed LOGIC ---
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

                          // Get user data from the model
                          final email = widget.userModel.email;
                          final uid = widget.userModel.uid;

                          // Generate the room details
                          final roomCode = _generateRoomCode(6);
                          final roomLink =
                              "https://beehiveapp.page.link/$roomCode";

                          // Create the new RoomModel object
                          final newRoom = RoomModel(
                            id: roomCode, // The doc ID is the room code
                            className: className,
                            section: section,
                            subject: subject,
                            roomCode: roomCode,
                            roomLink: roomLink,
                            createdBy: email,
                            creatorId: uid,
                            // createdAt will be set by the service
                          );

                          try {
                            // Call the service to create the room
                            await firestoreService.rooms.createRoom(newRoom);
                            
                            if (mounted) {
                              Navigator.pop(context); // Close the modal
                              setState(() => roomCreated = true);
                            }
                          } catch (e) {
                             if (mounted) {
                               showMessage(context, "Failed to create room: $e");
                             }
                          }
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

  // ... (Your _buildInputField and _generateRoomCode methods are unchanged) ...
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    // ...
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.black,
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