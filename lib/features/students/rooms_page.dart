import 'package:beehive/core/models/module_model.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';
import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/utils/hexagonal.dart';
import 'package:beehive/features/students/join_room.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentRoomPage extends StatefulWidget {
  final void Function(String roomId, String moduleId)? onModuleSelected;
  
  // It MUST accept the userModel from StudentHomePage
  final UserModel userModel; 

  const StudentRoomPage({
    super.key,
    this.onModuleSelected,
    required this.userModel, // It is required
  });

  @override
  State<StudentRoomPage> createState() => _StudentRoomPageState();
}

class _StudentRoomPageState extends State<StudentRoomPage> {
  
  @override
  Widget build(BuildContext context) {
    // Get the service once
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      // This body is now refactored to use efficient streams
      body: StreamBuilder<List<String>>(
        // 1. Get the list of joined room IDs
        stream: firestoreService.users.getJoinedRoomIdsStream(widget.userModel.uid),
        builder: (context, idSnapshot) {
          if (idSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!idSnapshot.hasData || idSnapshot.data!.isEmpty) {
            return const Center(child: Text('No rooms joined yet.'));
          }

          final roomIds = idSnapshot.data!;

          // 2. Get the list of RoomModel objects from the IDs
          return StreamBuilder<List<RoomModel>>(
            stream: firestoreService.rooms.getRoomsStream(roomIds),
            builder: (context, roomSnapshot) {
              if (!roomSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = roomSnapshot.data!;

              // 3. Build the list using the clean List<RoomModel>
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  
                  // 4. Pass the full, clean models to the card
                  return RoomExpansionCard(
                    room: room,
                    userModel: widget.userModel,
                    onModuleSelected: widget.onModuleSelected,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: HexFloatingButton(
        size: 70,
        color: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              // Pass the userModel to the dialog
              child: JoinRoomDialog(userModel: widget.userModel),
            ),
          );
        },
      ),
    );
  }
}

//
// REFACTORED RoomExpansionCard
//
class RoomExpansionCard extends StatefulWidget {
  final RoomModel room;
  final UserModel userModel;
  final Function(String, String)? onModuleSelected;

  const RoomExpansionCard({
    Key? key,
    required this.room,
    required this.userModel,
    this.onModuleSelected,
  }) : super(key: key);

  @override
  _RoomExpansionCardState createState() => _RoomExpansionCardState();
}

class _RoomExpansionCardState extends State<RoomExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. HEADER (Fetches professor's name cleanly)
          FutureBuilder<UserModel?>(
            future: Provider.of<FirestoreService>(context, listen: false)
                .users
                .getUser(widget.room.creatorId),
            builder: (context, profSnapshot) {
              String profName = 'Unknown Professor';
              if (profSnapshot.connectionState == ConnectionState.done &&
                  profSnapshot.hasData &&
                  profSnapshot.data != null) {
                profName = profSnapshot.data!.fullName;
              }

              return Container(
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
                                widget.room.className,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                widget.room.subject,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                              SizedBox(height: 20),
                              Text(
                                profName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
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
              );
            },
          ),

          // 2. BODY (The animated expandable part)
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Container(
              color: const Color.fromARGB(255, 255, 206, 109),
              child: _buildExpandableChildren(),
            ),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // 10. REFACTORED Expandable Children
  Widget _buildExpandableChildren() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // 1. Stream the linked module IDs
    return StreamBuilder<List<String>>(
      stream: firestoreService.modules.getLinkedModuleIdsStream(widget.room.id),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.black54)));
        }
        if (!idSnapshot.hasData || idSnapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child:
                Text('No modules linked yet.', style: TextStyle(color: Colors.black87)),
          );
        }

        final moduleIds = idSnapshot.data!;

        // 2. Stream the ModuleModel objects from the IDs
        return StreamBuilder<List<ModuleModel>>(
          stream: firestoreService.modules.getModulesByIdsStream(moduleIds),
          builder: (context, moduleSnapshot) {
            if (!moduleSnapshot.hasData) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.black54)));
            }

            final modules = moduleSnapshot.data!;

            // 3. Build the list of modules
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: modules.map((mod) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    color: Colors.white,
                    child: ListTile(
                      title: Center(
                        child: Text(
                          mod.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () async {
                        // 4. Call the service to set the recent module
                        await firestoreService.users.setRecentModule(
                          widget.userModel.uid,
                          widget.room.id,
                          mod.id,
                          mod.title,
                        );

                        if (widget.onModuleSelected != null) {
                          widget.onModuleSelected!(widget.room.id, mod.id);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}