import 'package:beehive/features/teachers/create_room.dart';
import 'package:beehive/design/hexagonal.dart';
import 'package:beehive/features/teachers/t_modules_page.dart';
import 'package:beehive/features/teachers/t_notifications_page.dart';
import 'package:beehive/features/teachers/t_profile_page.dart';
import 'package:beehive/features/teachers/teacher_drawer.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../start/google_sign_in.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  List<Widget> _pages(List<QueryDocumentSnapshot> rooms) => [
        // This is the main content for the 'Home' tab
        rooms.isEmpty
            ? const Center(
                child: Text(
                  "No rooms created yet. Tap the '+' to add one!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        "$className - $subject",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Section: $section"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              ),
        const ModulesPage(),
        const NotificationsPage(),
        const ProfilePage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (roomSnapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Error loading rooms.')));
        }

        final rooms = roomSnapshot.data?.docs ?? [];

        return Scaffold(
          drawer: TeacherDrawer(
            user: currentUser,
            rooms: rooms,
            onSignOut: signout, // This is the line you need to add
          ),
          appBar: AppBar(
            title: Text(['Home', 'Modules', 'Notifications', 'Profile'][_selectedIndex]),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: signout,
                tooltip: 'Logout',
              ),
            ],
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