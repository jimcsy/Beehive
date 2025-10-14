import 'package:beehive/design/hexagonal.dart';
import 'package:beehive/features/students/join_room.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRoomPage extends StatefulWidget {
  const StudentRoomPage({super.key});

  @override
  State<StudentRoomPage> createState() => _StudentRoomPageState();
}

class _StudentRoomPageState extends State<StudentRoomPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('joinedRooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No rooms joined yet.'),
            );
          }

          final joinedRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: joinedRooms.length,
            itemBuilder: (context, index) {
              final roomId = joinedRooms[index]['roomId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .get(),
                builder: (context, roomSnapshot) {
                  if (!roomSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final room = roomSnapshot.data!;
                  final className = room['className'] ?? 'No Name';
                  final subject = room['subject'] ?? 'No Subject';
                  final prof = room['createdBy'] ?? 'Unknown';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      title: Text(className,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('$subject\nProfessor: $prof'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to room detail page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening $className...')),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // Optional floating button
      floatingActionButton: HexFloatingButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const JoinRoomDialog(),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
