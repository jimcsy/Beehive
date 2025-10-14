import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your page files
import 't_modules_page.dart';
import 't_settings_page.dart';
import 't_about_page.dart';

class TeacherDrawer extends StatelessWidget {
  final User? user;
  final List<QueryDocumentSnapshot> rooms; // Accepts the list of rooms
  final VoidCallback onSignOut;

  const TeacherDrawer({
    super.key,
    required this.user,
    required this.rooms, // Requires the rooms list
    required this.onSignOut,
  });

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This logic is for the user profile header
    final displayName = user?.displayName ?? 'Teacher Name';
    final email = user?.email ?? 'No email';
    final photoURL = user?.photoURL;
    final firstInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  accountEmail: Text(
                    email,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white70,
                    backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                    child: photoURL == null
                        ? Text(
                            firstInitial,
                            style: const TextStyle(fontSize: 40.0, color: Colors.black54),
                          )
                        : null,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFDC830), Color(0xFFF37335)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                const SizedBox(height: 20,),

                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Rooms'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                // This part dynamically builds a list of rooms
                ...rooms.map((roomDoc) {
                  final roomData = roomDoc.data() as Map<String, dynamic>;
                  final className = roomData['className'] ?? 'Unnamed Room';
                  final section = roomData['section'] ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 32.0),
                    leading: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.code, color: Colors.white, size: 18),
                    ),
                    title: Text(className),
                    subtitle: Text(section),
                    onTap: () {
                      _navigateTo(context, const ModulesPage());
                    },
                  );
                }).toList(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    _navigateTo(context, const TSettingsPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    _navigateTo(context, const TAboutPage());
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Log out'),
            trailing: const Icon(Icons.logout),
            onTap: onSignOut,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}