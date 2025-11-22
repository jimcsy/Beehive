import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/shared/notification_page.dart';
import 'package:beehive/features/shared/profile_page.dart';
import 'package:beehive/features/teachers/create_room.dart';
import 'package:beehive/utils/hexagonal.dart';
import 'package:beehive/features/teachers/notify_students.dart'; 
import 'package:beehive/features/teachers/rooms/view_room.dart';
import 'package:beehive/features/teachers/module_page.dart';
import 'package:beehive/features/shared/drawer.dart';
import 'package:beehive/core/provider/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:beehive/core/services/google_auth_services.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';
import 'package:beehive/features/teachers/archive_room_page.dart'; 

class TeacherHomePage extends StatefulWidget {
  final UserModel userModel;
  const TeacherHomePage({
    super.key,
    required this.userModel,
  });

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper function for the confirmation dialog
  Future<bool?> _showConfirmationDialog(BuildContext context, String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        actions: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA27221),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 200, 95),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Yes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _pages(List<RoomModel> rooms) => [
        // 🏠 HOME TAB
        rooms.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16), 
                  child: Text(
                    "No rooms created yet.",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final className = room.className;
                  final subject = room.subject ?? ''; // Handle nullable subject
                  final section = room.section;
                  final roomId = room.id;

                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA0701F), Color(0xFFE8A319)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewRoomPage(
                                  roomId: roomId,
                                  className: className,
                                  subject: subject,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      className,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      section,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: false,
                                        isDismissible: true,
                                        enableDrag: false,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        builder: (context) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20, horizontal: 24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Archive option
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.pop(context); // Close modal
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ArchiveRoomPage( 
                                                          roomId: roomId,
                                                          className: className,
                                                          subject: subject, 
                                                          teacherName: widget.userModel.fullName, 
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.archive_outlined,
                                                          color: Color(0xFFE8A319)), 
                                                      SizedBox(width: 10),
                                                      Text(
                                                        "Archive Room",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 16), 

                                                // Delete option
                                                GestureDetector(
                                                  onTap: () async {
                                                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                    final navigator = Navigator.of(context); 
                                                    final teacherName = widget.userModel.fullName;

                                                    navigator.pop(); 

                                                    final confirm = await _showConfirmationDialog(
                                                      navigator.context,
                                                      'Delete Room',
                                                      'Are you sure you want to delete "$className"?',
                                                    );

                                                    if (confirm ?? false) {
                                                      try {
                                                        await notifyStudentsOnRoomDelete(
                                                          className: className,
                                                          subject: subject,
                                                          roomId: roomId,
                                                          teacherName: teacherName,
                                                          firestoreService: firestoreService,
                                                        );

                                                        await firestoreService.rooms.deleteRoom(roomId);

                                                        scaffoldMessenger.showSnackBar(SnackBar(
                                                          content: Text('Room "$className" deleted successfully'),
                                                        ));
                                                      } catch (e) {
                                                        scaffoldMessenger.showSnackBar(const SnackBar(
                                                          content: Text('Failed to delete room'),
                                                        ));
                                                        debugPrint('Delete room error: $e');
                                                      }
                                                    }
                                                  },
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.delete_outline,
                                                          color: Colors.red),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        "Delete Room",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Icon(Icons.more_horiz,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

        // 📚 MODULES
        ModulesPage(userModel: widget.userModel),

        // 🔔 NOTIFICATIONS
        const NotificationPage(),

        // 👤 PROFILE
        ProfilePage(onGoToHome: () => _onItemTapped(0)),
      ];

  Future<void> signout() async {
    try {
      final googleProvider =
          Provider.of<GoogleSignInProvider>(context, listen: false);
      await googleProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<RoomModel>>(
      stream: firestoreService.rooms.getTeacherRoomsStream(widget.userModel.uid),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (roomSnapshot.hasError) {
          return const Scaffold(
              body: Center(child: Text('Error loading rooms.')));
        }

        final rooms = roomSnapshot.data ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
          // --- DRAWER IMPLEMENTATION WITH FIX ---
          drawer: UserDrawer(
            userModel: widget.userModel, 
            rooms: rooms, 
            onSignOut: signout,
            // FIX: When a teacher clicks a room in Drawer, navigate to Room View
            onRoomSelected: (room) {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewRoomPage(
                    roomId: room.id,
                    className: room.className,
                    subject: room.subject ?? '',
                  ),
                ),
              );
            },
          ),
          appBar: _selectedIndex == 3
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  centerTitle: false,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: 'Open Menu',
                    ),
                  ),
                  title: Text(
                      ['Home', 'Modules', 'Notifications', 'Profile'][_selectedIndex]),
                  
                  actions: _selectedIndex == 0
                      ? [
                          IconButton(
                            icon: const Icon(Icons.archive, color: Colors.black),
                            tooltip: 'View Archived Rooms',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ArchivedRoomsPage(), 
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ]
                      : null,
                ),
          body: _pages(rooms)[_selectedIndex],
          floatingActionButton: _selectedIndex == 0
              ? HexFloatingButton(
                  size: 70,
                  color: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) =>
                          CreateRoom(userModel: widget.userModel),
                    );
                  },
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Modules'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications), label: 'Notifications'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}