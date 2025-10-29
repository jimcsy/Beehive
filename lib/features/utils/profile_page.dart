import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:beehive/features/utils/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onGoToHome;

  const ProfilePage({super.key, required this.onGoToHome});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getOrCreateUserProfile();
  }

  Future<DocumentSnapshot> _getOrCreateUserProfile() async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid);

    final doc = await userRef.get();

    if (!doc.exists) {
      try {
        await userRef.set({
          'displayName': currentUser!.displayName,
          'email': currentUser!.email,
          'photoURL': currentUser!.photoURL,
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return await userRef.get();
      } catch (e) {
        throw Exception('Failed to create user profile: $e');
      }
    } else {
      return doc;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar icons to light (white) for the dark header
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error loading profile.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final String firstName = userData?['firstName'] ?? '';
          final String lastName = userData?['lastName'] ?? '';

          // Combine them for display, with a fallback
          final String displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
              ? '$firstName $lastName'.trim()
              : 'Student Name';
          final email = userData?['email'] ?? 'student.email@example.com';
          final photoURL = userData?['photoURL'];

          // 1. The main widget is a Stack to layer all elements
          return Stack(
            children: [
              // 2. The scrolling content (bottom layer)
              SingleChildScrollView(
                // Add padding so the content starts below the profile pic
                padding: const EdgeInsets.only(top: 290), 
                child: Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Badges'),
                    _buildPlaceholderBox(height: 120),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Achievements'),
                    _buildPlaceholderBox(height: 180),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 3. The header background using your rectangle.png (middle layer)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/icons/rectangle.png', // Using your asset
                  height: 265, // Adjust height as needed
                  fit: BoxFit.cover,
                ),
              ),

              // 4. The BeeHive logo and text (top layer)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/logo_white.png',
                          height: 28, // Adjust size as needed
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/icons/BeeHive.png',
                          height: 15, // Adjust size as needed
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 5. The Profile Picture (top layer)
              Positioned(
                top: 150, // Position it to overlap the header and body
                // Center horizontally
                left: MediaQuery.of(context).size.width / 2 - 65, 
                child: ClipPath(
                  clipper: _HexagonalClipper(),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      image: photoURL != null
                          ? DecorationImage(
                              image: NetworkImage(photoURL),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoURL == null
                        ? Center(
                            child: Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                              style: const TextStyle(fontSize: 60, color: Colors.black54),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              // 6. The Back and Edit buttons (top-most layer)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: widget.onGoToHome,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () async {
                      // --- Academic Explanation ---
                      // 1. We 'await' the result from Navigator.push. This pauses
                      //    this function until the 'EditProfilePage' is 'popped' (closed).
                      final bool? profileWasUpdated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            // 2. We pass the 'userData' map we already fetched
                            //    into the constructor of our new edit page.
                            //    This is how the edit page knows the current name/photoURL.
                            userData: userData ?? {},
                          ),
                        ),
                      );

                      // 3. In edit_profile.dart, we wrote 'Navigator.pop(true)'
                      //    on a successful save. We check for that 'true' value here.
                      //    This is a common "callback" pattern for navigation.
                      //
                      // 4. The 'if (mounted)' check is a best practice. It ensures
                      //    this widget is still part of the tree before calling setState
                      //    (prevents errors if the user, for example, logged out
                      //    while the edit page was open).
                      if (profileWasUpdated == true && mounted) {
                        // 5. This is the most important part for a "smooth" experience:
                        //    We call setState and re-assign our '_userFuture'.
                        //    This tells the FutureBuilder to re-run its 'future'
                        //    (the _getOrCreateUserProfile() function), which
                        //    fetches the new, updated data from Firestore and
                        //    refreshes the UI.
                        setState(() {
                          _userFuture = _getOrCreateUserProfile();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widgets (No changes needed below) ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

// --- Clipper Class (Only the Hexagonal one is needed now) ---

class _HexagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}