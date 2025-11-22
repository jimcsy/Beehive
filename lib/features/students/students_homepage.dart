import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/shared/notification_page.dart';
import 'package:beehive/features/shared/profile_page.dart';
import 'package:beehive/features/students/rooms_page.dart';
import 'package:beehive/features/shared/drawer.dart'; // Ensure this file contains the updated UserDrawer code I sent previously
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
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  StudentHomePageState createState() => StudentHomePageState();
}

class StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;
  
  // TRACKING STATE
  String? _recentRoomId;
  String? _recentModuleId;
  
  // NEW: specific room selected from Drawer
  RoomModel? _selectedRoomFromDrawer; 

  @override
  void initState() {
    super.initState();
    _loadRecentModule();
  }

  // --- HOME TAB BUILDER ---
  Widget _buildHomeTab() {
    if (_recentRoomId != null && _recentModuleId != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.userModel.uid;
      return ViewUnitsTab(
        roomId: _recentRoomId!,
        moduleId: _recentModuleId!,
        userId: uid,
      );
    } else {
      return const Center(child: Text("Loading recent modules..."));
    }
  }

  // --- HANDLERS ---

  // 1. When a student taps a module hexagon (inside the room page)
  void _handleModuleSelection(String roomId, String moduleId) {
    setState(() {
      _recentRoomId = roomId;
      _recentModuleId = moduleId;
      _selectedIndex = 0; // Switch to Home tab to view the content
    });
  }

  // 2. When a student clicks a Room in the Drawer
  void _handleDrawerRoomSelection(RoomModel room) {
    setState(() {
      _selectedRoomFromDrawer = room; // Store the selected room
      _selectedIndex = 1; // Switch to the "Rooms" tab
    });
  }

  // 3. Tab Selection Handler (Bottom Nav)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // If user manually clicks the "Rooms" tab (index 1), 
      // we clear the specific drawer selection so they see the full list (Yellow cards)
      if (index == 1) {
        _selectedRoomFromDrawer = null;
      }
    });
  }

  // 4. Handle Back Button (in AppBar or Physical Back)
  void _handleBackToRoomList() {
    setState(() {
      _selectedRoomFromDrawer = null; // Clear selection to show the list again
    });
  }

  // --- DATA LOADING ---
  Future<void> _loadRecentModule() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final recentModule = await firestoreService.users.getRecentModule(widget.userModel.uid);

    if (recentModule != null && mounted) {
      setState(() {
        _recentRoomId = recentModule.roomId;
        _recentModuleId = recentModule.moduleId;
      });
    }
  }

  // --- AUTH ---
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

      final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);
      await googleProvider.logout();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log out')),
        );
      }
    }
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Handle Android Back Button
    return PopScope(
      canPop: _selectedRoomFromDrawer == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackToRoomList();
      },
      child: StreamBuilder<List<String>>(
        stream: firestoreService.users.getJoinedRoomIdsStream(widget.userModel.uid),
        builder: (context, idSnapshot) {
          if (idSnapshot.connectionState == ConnectionState.waiting && !idSnapshot.hasData) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (idSnapshot.hasError) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text('Error loading your room IDs.')),
            );
          }

          final roomIds = idSnapshot.data ?? [];

          return StreamBuilder<List<RoomModel>>(
            stream: firestoreService.rooms.getRoomsStream(roomIds),
            builder: (context, roomSnapshot) {
              final rooms = roomSnapshot.data ?? [];

              // Determine Title based on state
              String appBarTitle = ['Home', 'Rooms', 'Notifications', 'Profile'][_selectedIndex];
              if (_selectedIndex == 1 && _selectedRoomFromDrawer != null) {
                appBarTitle = _selectedRoomFromDrawer!.className;
              }

              // Determine Leading Icon (Menu vs Back)
              Widget? leadingIcon;
              if (_selectedIndex == 1 && _selectedRoomFromDrawer != null) {
                leadingIcon = IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackToRoomList,
                );
              } else {
                leadingIcon = Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                );
              }

              /// PAGES
              final List<Widget> pages = [
                // 0: Home
                _buildHomeTab(),
                
                // 1: Rooms
                // We pass the 'initialRoomId' if a room was selected from the Drawer.
                // Note: Your StudentRoomPage needs to support 'initialRoomId' logic to show hexagons immediately.
                StudentRoomPage(
                  userModel: widget.userModel,
                  initialRoomId: _selectedRoomFromDrawer?.id, 
                  onModuleSelected: (roomId, moduleId) {
                    _handleModuleSelection(roomId, moduleId);
                  },
                ),
                
                // 2: Notifications
                const NotificationPage(),
                
                // 3: Profile
                ProfilePage(
                  onGoToHome: () => _onItemTapped(0),
                ),
              ];

              return Scaffold(
                backgroundColor: Colors.white,
                
                // UPDATED DRAWER CALL
                drawer: UserDrawer(
                  userModel: widget.userModel,
                  rooms: rooms,
                  onSignOut: signout,
                  onRoomSelected: _handleDrawerRoomSelection, // <--- CONNECTED HERE
                ),
                
                appBar: _selectedIndex == 3
                    ? null
                    : AppBar(
                        backgroundColor: Colors.white,
                        title: Text(appBarTitle),
                        leading: leadingIcon,
                      ),
                
                body: IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
                
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: const Color(0xFFA27221),
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.meeting_room), label: 'Room'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.notifications), label: 'Notifications'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}