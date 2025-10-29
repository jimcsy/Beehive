import 'package:beehive/design/hexagonal.dart';
import 'package:beehive/features/students/join_room.dart';
import 'package:beehive/features/students/s_notification_page.dart';
import 'package:beehive/features/students/s_profile_page.dart';
import 'package:beehive/features/students/s_rooms_page.dart';
import 'package:beehive/features/utils/drawer.dart'; // Make sure this path is correct
import 'package:beehive/features/students/modules/view_lesson.dart';
import 'package:beehive/start/loader.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../start/google_sign_in.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  StudentHomePageState createState() => StudentHomePageState();
}

class StudentHomePageState extends State<StudentHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;

  // Store recent module to show in Home
  String? _recentRoomId;
  String? _recentModuleId;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    loadRecentModule();
  }

  Future<void> fetchUserRole() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        setState(() {
          role = doc['role'];
          isLoading = false;
        });
      } else {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user?.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          setState(() {
            role = query.docs.first['role'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      setState(() => isLoading = false);
    }
  }

  // Load last opened module if exists
  Future<void> loadRecentModule() async {
    final recentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('recent')
        .doc('lastOpened')
        .get();

    if (recentDoc.exists) {
      final data = recentDoc.data()!;
      setState(() {
        _recentRoomId = data['roomId'];
        _recentModuleId = data['moduleId'];
      });
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

  // Build pages dynamically
  List<Widget> _buildPages() {
    return [
      if (_recentRoomId != null && _recentModuleId != null)
        ViewUnitsTab(roomId: _recentRoomId!, moduleId: _recentModuleId!)
      else
        const Center(child: Text("No modules available yet.")),

      StudentRoomPage(
        onModuleSelected: (roomId, moduleId) {
          setState(() {
            _recentRoomId = roomId;
            _recentModuleId = moduleId;
            _selectedIndex = 0; // switch to Home tab
          });
        },
      ),
      const StudentNotificationPage(),
      const StudentProfilePage(),
    ];
  }

  //
  // --- START OF UPDATED CODE ---
  //

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // If not, you can't query their rooms. Show a login prompt or different UI.
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see your rooms.'),
        ),
      );
    }

    // 1. Outer StreamBuilder: Gets the list of room IDs from /users/.../joinedRooms
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedRooms')
          .snapshots(),
      builder: (context, userRoomsSnapshot) {
        if (userRoomsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()));
        }
        if (userRoomsSnapshot.hasError) {
          return const Scaffold(
            backgroundColor: Colors.white,
              body: Center(child: Text('Error loading your rooms.')));
        }

        final joinedRoomsDocs = userRoomsSnapshot.data?.docs ?? [];

        if (joinedRoomsDocs.isEmpty) {
          // User is not in any rooms. Build the UI with an empty list.
          return _buildScaffold(context, currentUser, pages, []);
        }

        // 2. Extract the 'roomId' strings from the documents
        final List<String> roomIds = joinedRoomsDocs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              // Check if data is not null AND contains 'roomId'
              if (data != null && data.containsKey('roomId')) {
                return data['roomId'] as String?;
              }
              return null;
            })
            .whereType<String>() // This filters out any nulls
            .toList();

        if (roomIds.isEmpty) {
          // User has docs in 'joinedRooms', but no 'roomId' fields.
          return _buildScaffold(context, currentUser, pages, []);
        }

        // 3. Inner StreamBuilder: Gets the actual room details from 'rooms' collection
        return StreamBuilder<QuerySnapshot>(
          // Use the "whereIn" query to get all rooms in one request
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .where(FieldPath.documentId, whereIn: roomIds)
              .snapshots(),
          builder: (context, roomSnapshot) {
            if (roomSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (roomSnapshot.hasError) {
              return const Scaffold(
                  body: Center(child: Text('Error loading room details.')));
            }

            // THIS IS THE FINAL, CORRECT LIST OF ROOMS
            final rooms = roomSnapshot.data?.docs ?? [];

            // 4. Build the Scaffold and pass the correct 'rooms' list
            return _buildScaffold(context, currentUser, pages, rooms);
          },
        );
      },
    );
  }

  // I moved your Scaffold into its own method to keep the build method clean
  Widget _buildScaffold(
    BuildContext context,
    User currentUser,
    List<Widget> pages,
    List<QueryDocumentSnapshot> rooms, // <-- The correctly fetched list
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: UserDrawer(
        user: currentUser,
        rooms: rooms, // <-- Pass the correct list here
        onSignOut: signout,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            Text(['Home', 'Rooms', 'Notifications', 'Profile'][_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu), // ☰ three-line button
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open Menu',
          ),
        ),
      ),
      body: pages[_selectedIndex],
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
  }
  //
  // --- END OF UPDATED CODE ---
  //
}