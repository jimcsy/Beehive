import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your page files
import '../teachers/module_page.dart';
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
    // We only get email and photoURL here.
    // DisplayName will be fetched from Firestore.
    final email = user?.email ?? 'No email';
    final photoURL = user?.photoURL;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // --- THIS IS THE MODIFIED SECTION ---
                  // We wrap the DrawerHeader in a FutureBuilder to get custom user data
                  FutureBuilder<DocumentSnapshot>(
                    // Fetch the user's document from Firestore
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid) // Use user?.uid for safety
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      
                      // Defaults while loading or if data is missing
                      String displayName = 'Loading...';
                      String firstInitial = 'U';
        
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          // Data found in Firestore
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final firstName = data['firstName'] ?? '';
                          final lastName = data['lastName'] ?? '';
                          
                          // Capitalize the first letter of each name
                          final capitalizedFirstName = firstName.isNotEmpty 
                              ? '${firstName[0].toUpperCase()}${firstName.substring(1)}' 
                              : '';
                          final capitalizedLastName = lastName.isNotEmpty 
                              ? '${lastName[0].toUpperCase()}${lastName.substring(1)}' 
                              : '';
        
                          displayName = '$capitalizedFirstName $capitalizedLastName'.trim();
                          if (displayName.isEmpty) {
                            displayName = 'User Name'; // Fallback if names are empty
                          }
                          
                          // Get initial from firstName, or lastName, or default to 'U'
                          firstInitial = capitalizedFirstName.isNotEmpty
                              ? capitalizedFirstName[0].toUpperCase()
                              : (capitalizedLastName.isNotEmpty ? capitalizedLastName[0].toUpperCase() : 'U');
        
                        } else {
                          // No document found in Firestore, use email as fallback
                          displayName = user?.displayName ?? 'User Name';
                          firstInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
                        }
                      } else if (snapshot.hasError) {
                        displayName = 'Error';
                        firstInitial = 'E';
                      }
        
                      // Now build the DrawerHeader with the fetched data
                      return DrawerHeader(
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
                                    width: 75, // 2 × radius
                                    height: 75,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white, // Stroke color
                                        width: 1.0,  // Stroke thickness
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.white70,
                                      backgroundImage:
                                          photoURL != null ? NetworkImage(photoURL) : null,
                                      child: photoURL == null
                                          ? Text(
                                              firstInitial, // <-- Use the fetched initial
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
                                      displayName, // <-- Use the fetched name
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
                                      email, // <-- Use the email from above
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
                      );
                    },
                  ),
                  // --- END OF MODIFIED SECTION ---
        
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
                      title: Text(className, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      subtitle: Text(section, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400)),
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
      ),
    );
  }
}

