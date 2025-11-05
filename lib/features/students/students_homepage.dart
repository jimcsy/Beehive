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

  // --- 1. THIS IS THE FIX ---
  // We create the list of pages here, in initState.
  // This ensures they are created ONLY ONCE and their state is preserved.
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadRecentModule();
    
    // Initialize the page list once
    _pages = [
      // Home Tab
      _buildHomeTab(), // Use a helper function for the home tab
      
      // Room Tab
      StudentRoomPage(
        userModel: widget.userModel, 
        onModuleSelected: (roomId, moduleId) {
          _handleModuleSelection(roomId, moduleId);
        },
      ),
      
      // Notifications Tab
      const NotificationPage(),
      
      // Profile Tab
      ProfilePage(onGoToHome: () => _onItemTapped(0)),
    ];
  }

  // Helper function to build the home tab
  Widget _buildHomeTab() {
    if (_recentRoomId != null && _recentModuleId != null) {
      return ViewUnitsTab(roomId: _recentRoomId!, moduleId: _recentModuleId!);
    } else {
      return const Center(child: Text("No modules available yet."));
    }
  }

  // Helper function to update state and rebuild pages
  void _handleModuleSelection(String roomId, String moduleId) {
    setState(() {
      _recentRoomId = roomId;
      _recentModuleId = moduleId;
      _selectedIndex = 0; // switch to Home tab
      
      // --- 2. THIS IS THE OTHER PART OF THE FIX ---
      // We must *rebuild* the page list to update the Home tab
      _pages = [
        _buildHomeTab(), // This will now have the new recent module
        _pages[1], // Re-use the existing StudentRoomPage instance
        _pages[2], // Re-use the existing NotificationPage instance
        _pages[3], // Re-use the existing ProfilePage instance
      ];
    });
  }
  // --- END OF FIX ---


  Future<void> _loadRecentModule() async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final recentModule =
        await firestoreService.users.getRecentModule(widget.userModel.uid);

    if (recentModule != null) {
      if (mounted) {
        setState(() {
          _recentRoomId = recentModule.roomId;
          _recentModuleId = recentModule.moduleId;
          
          // Rebuild pages list if recent module is loaded
          _pages[0] = _buildHomeTab();
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

  // This function is no longer needed, we defined _pages in initState
  // List<Widget> _buildPages() { ... }

  @override
  Widget build(BuildContext context) {
    // We REMOVED final pages = _buildPages() from here.
    
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // This StreamBuilder is now *only* for the UserDrawer.
    // It will no longer cause the body to rebuild.
    return StreamBuilder<List<String>>(
      stream: firestoreService.users.getJoinedRoomIdsStream(widget.userModel.uid),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
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

            // --- 3. THE FINAL PART OF THE FIX ---
            // Build the scaffold, but use an IndexedStack for the body
            return Scaffold(
              backgroundColor: Colors.white,
              drawer: UserDrawer(
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
              // Use an IndexedStack to preserve the state of each tab
              body: IndexedStack(
                index: _selectedIndex,
                children: _pages,
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
            // --- END OF FIX ---
          },
        );
      },
    );
  }
}