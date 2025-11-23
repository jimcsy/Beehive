import 'package:beehive/debug/add_module_debug.dart';
import 'package:beehive/debug/reading.dart';
import 'package:beehive/python_ide/ide_test_screen.dart';
import 'package:flutter/material.dart';

// --- IMPORTS FOR MODELS ---
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';

// --- IMPORTS FOR PAGES ---
import '../teachers/module_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
// Note: We removed the direct imports for StudentRoomPage here because 
// the Parent/Home screen should handle displaying that widget now.

class UserDrawer extends StatelessWidget {
  final UserModel userModel;
  final List<RoomModel> rooms;
  final VoidCallback onSignOut;
  // NEW: Callback to tell the Home Screen which room was clicked
  final Function(RoomModel room) onRoomSelected; 

  const UserDrawer({
    super.key,
    required this.userModel,
    required this.rooms,
    required this.onSignOut,
    required this.onRoomSelected, // Required now
  });

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  bool _detectIsTeacher() {
    try {
      final dynamic um = userModel as dynamic;
      if (um.isTeacher != null) {
        return um.isTeacher == true;
      }
      if (um.role != null) {
        final String r = um.role.toString().toLowerCase();
        return r == 'teacher' || r == 'instructor' || r == 'admin';
      }
    } catch (_) {
      // ignore
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = userModel.fullName;
    final String email = userModel.email;
    final String firstInitial = userModel.firstName.isNotEmpty
        ? userModel.firstName[0].toUpperCase()
        : 'U';
    final String? photoURL = null;

    // We still detect teacher to adjust logic if needed, 
    // but mainly we want to use the callback.
    final bool isTeacher = _detectIsTeacher();

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white70,
                                  backgroundImage: photoURL != null
                                      ? NetworkImage(photoURL)
                                      : null,
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
                    title: const Text('Rooms', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      // Optional: Call onRoomSelected with null or a specific logic 
                      // if you want "Rooms" to reset the view to the list.
                    },
                  ),

                  // Dynamic room list
                  ...rooms.map((room) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 32.0),
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.brown,
                        child: Icon(Icons.code, color: Colors.white, size: 18),
                      ),
                      title: Text(
                        room.className,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        room.section,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w400),
                      ),
                      onTap: () {
                        // --- FIX IS HERE ---
                        Navigator.pop(context); // Close the drawer
                        
                        // Instead of Navigator.push, we pass the data back to the Home Screen
                        onRoomSelected(room); 
                      },
                    );
                  }).toList(),

                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.terminal),
                    title: const Text('Swarm', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      _navigateTo(context, const IdeScreen());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      _navigateTo(context, const TSettingsPage());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      _navigateTo(context, const TAboutPage());
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Log out', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.logout),
              onTap: onSignOut,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}