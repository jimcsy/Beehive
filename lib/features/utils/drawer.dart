import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your page files
import '../teachers/t_modules_page.dart';
import 'settings_page.dart';
import 'about_page.dart';

class UserDrawer extends StatelessWidget {
  final User? user;
  final List<QueryDocumentSnapshot> rooms; // Accepts the list of rooms
  final VoidCallback onSignOut;

  const UserDrawer({
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
                // ✅ Custom vertical layout for profile info
              DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFA0701F),
                  Color(0xFFE8A319),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
              // ✅ Use LayoutBuilder to adapt properly to constraints
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 75, // 2 × radius
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white, // Stroke color
                              width: 1.0,           // Stroke thickness
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white70,
                            backgroundImage:
                                photoURL != null ? NetworkImage(photoURL) : null,
                            child: photoURL == null
                                ? Text(
                                    firstInitial,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.black54,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 25,
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Rooms', style: TextStyle(fontSize: 14),), //style: TextStyle(fontSize: 14),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // 👇 Dynamically built room list
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
              title: const Text('Settings',style: TextStyle(fontSize: 14),),
              onTap: () {
                _navigateTo(context, const TSettingsPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About',style: TextStyle(fontSize: 14),),
              onTap: () {
                _navigateTo(context, const TAboutPage());
              },
            ),
          ],
        ),
      ),
      const Divider(),
      ListTile(
        title: const Text('Log out',style: TextStyle(fontSize: 14),),
        trailing: const Icon(Icons.logout),
        onTap: onSignOut,
      ),
      const SizedBox(height: 16),
    ],
  ),
);


  }
}