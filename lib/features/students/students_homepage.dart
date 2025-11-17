import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/shared/notification_page.dart';
import 'package:beehive/features/shared/profile_page.dart';
import 'package:beehive/features/students/rooms_page.dart';
import 'package:beehive/features/shared/drawer.dart';
import 'package:beehive/features/students/modules/view_lesson.dart';
import 'package:beehive/core/provider/loader.dart';
import 'package:beehive/core/provider/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:beehive/core/services/google_auth_services.dart';
import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/models/room_model.dart';

class StudentHomePage extends StatefulWidget {
  final UserModel userModel;
  const StudentHomePage({
    super.key,
    required this.userModel,
  });

  @override
  StudentHomePageState createState() => StudentHomePageState();
}

class StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  String? _recentRoomId;
  String? _recentModuleId;

  // --- 1. REMOVED the 'late List<Widget> _pages' from here ---
  // We will now build it in the 'build' method.

  @override
  void initState() {
    super.initState();
    _loadRecentModule();
    // --- 2. REMOVED the _pages list initialization ---
  }

  // Helper function to build the home tab
  Widget _buildHomeTab() {
    if (_recentRoomId != null && _recentModuleId != null) {
      // Use FirebaseAuth if available, otherwise fall back to the userModel UID
      final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
      return ViewUnitsTab(
        roomId: _recentRoomId!,
        moduleId: _recentModuleId!,
        userId: uid,
      );
    } else {
      // Return a placeholder or loading, this will be rebuilt
      // when _loadRecentModule() completes and calls setState.
      return const Center(child: Text("Loading recent modules..."));
    }
  }

  // This function now just updates state. The page list
  // will be rebuilt automatically in the 'build' method.
  void _handleModuleSelection(String roomId, String moduleId) {
    setState(() {
      _recentRoomId = roomId;
      _recentModuleId = moduleId;
      _selectedIndex = 0; // switch to Home tab
    });
  }

  Future<void> _loadRecentModule() async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final recentModule =
        await firestoreService.users.getRecentModule(widget.userModel.uid);

    if (recentModule != null) {
      if (mounted) {
        // Just call setState. The build method will do the rest.
        setState(() {
          _recentRoomId = recentModule.roomId;
          _recentModuleId = recentModule.moduleId;
        });
      }
    }
  }

  Future<void> signout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomLoader(),
        ),
      );

      final googleProvider =
          Provider.of<GoogleSignInProvider>(context, listen: false);
      await googleProvider.logout();

      Navigator.pop(context); // close loader
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // This StreamBuilder is for the UserDrawer's room list
    return StreamBuilder<List<String>>(
      stream: firestoreService.users.getJoinedRoomIdsStream(widget.userModel.uid),
      builder: (context, idSnapshot) {
        // We can show a loading screen for the whole page
        // while we wait for the *first* set of room IDs.
        if (idSnapshot.connectionState == ConnectionState.waiting && !idSnapshot.hasData) {
          return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()));
        }
        if (idSnapshot.hasError) {
          return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text('Error loading your room IDs.')));
        }

        final roomIds = idSnapshot.data ?? [];

        return StreamBuilder<List<RoomModel>>(
          stream: firestoreService.rooms.getRoomsStream(roomIds),
          builder: (context, roomSnapshot) {
            
            final rooms = roomSnapshot.data ?? [];

            // --- 3. THIS IS THE FIX ---
            // The _pages list is now built *inside* the build method.
            // It will always get the new, live `widget.userModel`.
            final List<Widget> pages = [
              // Home Tab
              _buildHomeTab(),
              
              // Room Tab
              StudentRoomPage(
                userModel: widget.userModel, // <-- Gets the NEW model
                onModuleSelected: (roomId, moduleId) {
                  _handleModuleSelection(roomId, moduleId);
                },
              ),
              
              // Notifications Tab
              const NotificationPage(),
              
              // Profile Tab
              ProfilePage(onGoToHome: () => _onItemTapped(0)),
            ];
            // --- END OF FIX ---

            return Scaffold(
              backgroundColor: Colors.white,
              drawer: UserDrawer(
                // The drawer always gets the new model from the Wrapper
                userModel: widget.userModel, 
                rooms: rooms, // Drawer gets the live-updated room list
                onSignOut: signout,
              ),
              appBar: _selectedIndex == 3
                  ? null
                  : AppBar(
                      backgroundColor: Colors.white,
                      centerTitle: false,
                      title: Text(['Home', 'Rooms', 'Notifications', 'Profile'][_selectedIndex]),
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          tooltip: 'Open Menu',
                        ),
                      ),
                    ),
              body: IndexedStack(
                index: _selectedIndex,
                children: pages, // Use the fresh list of pages
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: const Color(0xFFA27221),
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Room'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.notifications), label: 'Notifications'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}