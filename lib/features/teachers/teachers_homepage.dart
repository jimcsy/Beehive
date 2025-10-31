import 'package:beehive/features/shared/notification_page.dart';
import 'package:beehive/features/shared/profile_page.dart';
import 'package:beehive/features/teachers/create_room.dart';
import 'package:beehive/design/hexagonal.dart';
import 'package:beehive/features/teachers/notify_students.dart';
import 'package:beehive/features/teachers/rooms/view_room.dart';
import 'package:beehive/features/teachers/module_page.dart';
import 'package:beehive/features/shared/drawer.dart';
import 'package:beehive/features/shared/show_modal.dart';
import 'package:beehive/core/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/google_sign_in.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

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

  List<Widget> _pages(List<QueryDocumentSnapshot> rooms) => [
        // 🏠 HOME TAB
        rooms.isEmpty
            ? const Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                  final className = room['className'] ?? 'Unnamed Class';
                  final subject = room['subject'] ?? 'No Subject';
                  final section = room['section'] ?? 'No Section';
                  final roomId = room.id;

                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Card(
                  //elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFA0701F), Color(0xFFE8A319)], 
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12), // Match Card's shape
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
                            // Main content (title & subtitle)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "$className",
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  "$subject",
                                  style: const TextStyle(
                                      fontSize: 13 , fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text("$section",
                                      style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ), 
                              ],
                            ),
                            // Top-right menu button
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
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Archive option
                                            GestureDetector(
                                              onTap: () async {
                                                Navigator.pop(context); // Close modal
                                                // Archive logic here
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Room "$className" archived')),
                                                );
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.archive_outlined, color: Colors.blue),
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
                                                Navigator.pop(context); // Close modal first
                  
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: Colors.white,
                                                    title: const Text('Delete Room', textAlign: TextAlign.center, style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                    ),),
                                                    content: Text('Are you sure you want to delete "$className"?', textAlign: TextAlign.center, style: TextStyle(
                                                      fontSize: 12,
                                                    ),),
                                                    actions: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 1,
                                                            child: ElevatedButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              style: ButtonStyle(
                                                                backgroundColor: MaterialStateProperty.all(Color(0xFFA27221)),
                                                                foregroundColor: MaterialStateProperty.all(Colors.white),
                                                                shape: MaterialStateProperty.all(
                                                                RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(14),
                                                                ),),
                                                              ),
                                                              child: const Text('No'),
                                                            ),
                                                          ),
                                                          SizedBox(width: 10,),
                                                          Expanded(
                                                            flex: 1,
                                                            child: ElevatedButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              style: ButtonStyle(
                                                                backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 235, 200, 95)),
                                                                foregroundColor: MaterialStateProperty.all(Colors.white),
                                                                shape: MaterialStateProperty.all(
                                                                RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(14),
                                                                ),),
                                                              ),
                                                              child: const Text('Yes'),
                                                          ),
                                                          ),
                                                        ],
                                                      ),
                                                      
                                                    ],
                                                  ),
                                                );
                  
                                                if (confirm ?? false) {
                                                  try {
                                                    // Get teacher name for notification
                                                    final user = FirebaseAuth.instance.currentUser;
                                                    String teacherName = user?.displayName ?? user?.email ?? 'Teacher';
                                                    
                                                    // Notify students before deleting the room
                                                    await notifyStudentsOnRoomDelete(
                                                      className: className,
                                                      subject: subject,
                                                      roomId: roomId,
                                                      teacherName: teacherName,
                                                    );
                                                    
                                                    // Clean up: Delete all members from the room's members subcollection
                                                    final membersSnapshot = await FirebaseFirestore.instance
                                                        .collection('rooms')
                                                        .doc(roomId)
                                                        .collection('members')
                                                        .get();
                                                    
                                                    for (var memberDoc in membersSnapshot.docs) {
                                                      await memberDoc.reference.delete();
                                                    }
                                                    
                                                    // Delete the room
                                                    await FirebaseFirestore.instance
                                                        .collection('rooms')
                                                        .doc(roomId)
                                                        .delete();
                                                    
                                                    showMessage(context, 'Room "$className" deleted successfully');
                                                  } catch (e) {
                                                    showMessage(context, 'Failed to delete room');
                                                    debugPrint('Delete room error: $e');
                                                  }
                                                }
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete_outline, color: Colors.red),
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
                                child: const Icon(Icons.more_horiz, color: Colors.white),
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
        const ModulesPage(),

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
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('createdBy', isEqualTo: currentUser?.email)
          .snapshots(),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (roomSnapshot.hasError) {
          return const Scaffold(
              body: Center(child: Text('Error loading rooms.')));
        }

        final rooms = roomSnapshot.data?.docs ?? [];

        return Scaffold(
        backgroundColor: Colors.white,
        drawer: UserDrawer(
          user: currentUser,
          rooms: rooms,
          onSignOut: signout,
        ),
        appBar: _selectedIndex == 3 // 3 is the index for Profile
            ? null // Don't show an AppBar for the Profile tab
            : AppBar( // Show the AppBar for all other tabs
                backgroundColor: Colors.white,
                centerTitle: false,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu), // ☰ three-line button
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Open Menu',
                  ),
                ),
                title: Text(
                    ['Home', 'Modules', 'Notifications', 'Profile'][_selectedIndex]),
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
                      builder: (context) => const CreateRoom(),
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
