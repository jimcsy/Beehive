import 'package:beehive/utils/hexagonal.dart';
import 'package:beehive/features/students/join_room.dart';
import 'package:beehive/features/students/modules/view_lesson.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRoomPage extends StatefulWidget {
  final void Function(String roomId, String moduleId)? onModuleSelected;

  const StudentRoomPage({super.key, this.onModuleSelected});

  @override
  State<StudentRoomPage> createState() => _StudentRoomPageState();
}

class _StudentRoomPageState extends State<StudentRoomPage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0; // Controls FAB visibility
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            return const Center(child: Text('No rooms joined yet.'));
          }

          final joinedRooms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: joinedRooms.length,
            itemBuilder: (context, index) {
              final roomId = joinedRooms[index]['roomId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .get(),
                builder: (context, roomSnapshot) {
                  if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final room = roomSnapshot.data!;
                  final className = room['className'] ?? 'No Name';
                  final subject = room['subject'] ?? 'No Subject';
                  final profUid = room['creatorId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(profUid)
                        .get(),
                    builder: (context, profSnapshot) {
                      String profName = 'Unknown Professor';
                      if (profSnapshot.hasData && profSnapshot.data!.exists) {
                        final userData =
                            profSnapshot.data!.data() as Map<String, dynamic>?;
                        final firstName = userData?['firstName'] ?? '';
                        final lastName = userData?['lastName'] ?? '';
                        if (firstName.isNotEmpty || lastName.isNotEmpty) {
                          profName = '$firstName $lastName'.trim();
                        }
                      }

                      return RoomExpansionCard(
                            className: className,
                            subject: subject,
                            profName: profName,
                            roomId: roomId,
                            onModuleSelected: widget.onModuleSelected,
                          );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _selectedIndex == 0
    ? HexFloatingButton(
        size: 70,
        color: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black54, // darken the background
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent, // make dialog transparent
              insetPadding: const EdgeInsets.all(16),
              child: JoinRoomDialog(), 
            ),
          );
        },
      )
    : null,
    );
  }
}

class RoomExpansionCard extends StatefulWidget {
  final String className;
  final String subject;
  final String profName;
  final String roomId;
  final Function(String, String)? onModuleSelected;

  const RoomExpansionCard({
    Key? key,
    required this.className,
    required this.subject,
    required this.profName,
    required this.roomId,
    this.onModuleSelected,
  }) : super(key: key);

  @override
  _RoomExpansionCardState createState() => _RoomExpansionCardState();
}

class _RoomExpansionCardState extends State<RoomExpansionCard> {
  // This state is now stored INSIDE each card, not on the main page
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // This is CRITICAL for rounded corners
      child: Column( // The root widget is now a Column
        children: [
          // 1. HEADER (Your original InkWell, wrapped in the gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA0701F), Color(0xFFE8A319)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              splashColor: Colors.white24,
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.className,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            widget.subject,
                            style: const TextStyle(color: Colors.white,fontSize: 13,),
                          ),
                          SizedBox(height: 20,),
                          Text(
                            widget.profName,
                            style: const TextStyle(color: Colors.white,fontSize: 12,),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 2.0),
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. BODY (This animates in the new background color)
          AnimatedCrossFade(
            firstChild: Container(), // Empty when collapsed
            // Wrap the children in a new colored Container
            secondChild: Container(
              // --- I REMOVED THE 'width' PROPERTY ---
              color: const Color.fromARGB(255, 255, 206, 109), 
              child: _buildExpandableChildren(),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableChildren() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('modules')
          .snapshots(),
      builder: (context, moduleRefSnapshot) {
        if (!moduleRefSnapshot.hasData ||
            moduleRefSnapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No modules linked yet.',
              style: TextStyle(color: Colors.black87), // Dark text
            ),
          );
        }

        final linkedModules = moduleRefSnapshot.data!.docs;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('modules').get(),
          builder: (context, globalModulesSnapshot) {
            if (!globalModulesSnapshot.hasData) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Colors.black54, // Dark indicator
                ),
              ));
            }

            final globalModules = globalModulesSnapshot.data!.docs;

            final filteredModules = globalModules
                .where((gm) => linkedModules.any((lm) => lm.id == gm.id))
                .toList();

            // Add padding to this Column
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),  
              child: Column(
                children: filteredModules.map((mod) {
                  final title = mod['title'] ?? 'Untitled';
                  final moduleId = mod.id;
              
                  // --- START: This is the style you wanted ---
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      // Removed contentPadding: EdgeInsets.zero
                      
                      title: Center(
                        child: Text( 
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black, fontSize: 12,
                          
                          ),
                        ),
                      ),
                      onTap: () async {
                        final currentUser =
                            FirebaseAuth.instance.currentUser;
              
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser!.uid)
                            .collection('recent')
                            .doc('lastOpened')
                            .set({
                          'roomId': widget.roomId,
                          'moduleId': moduleId,
                          'title': title,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
              
                        if (widget.onModuleSelected != null) {
                          widget.onModuleSelected!(widget.roomId, moduleId);
                        }
                      },
                    ),
                  );
                  // --- END: This is the style you wanted ---
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
