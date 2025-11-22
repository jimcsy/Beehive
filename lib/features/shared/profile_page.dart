import 'package:beehive/utils/hexagonal.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:beehive/features/shared/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onGoToHome;

  const ProfilePage({super.key, required this.onGoToHome});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<DocumentSnapshot> _userFuture; // Removed 'final' to allow reassignment

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
      // 1. NEW USER:
      // Document doesn't exist, create it.
      try {
        await userRef.set({
          'displayName': currentUser!.displayName,
          'email': currentUser!.email,
          'photoURL': currentUser!.photoURL, 
          'role': 'student', 
          'createdAt': FieldValue.serverTimestamp(),
          // FIX: Explicitly initialize firstName and lastName for consistency
          'firstName': '', 
          'lastName': '',
        });
        // Return the new document we just created
        return await userRef.get();
      } catch (e) {
        throw Exception('Failed to create user profile: $e');
      }
    } else {
      // 2. EXISTING USER:
      // Document EXISTS. We need to check if it's missing data or display name.
      final userData = doc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> dataToUpdate = {};

      // CHECK 1: Is the photoURL null in our database?
      if (userData['photoURL'] == null && currentUser!.photoURL != null) {
        dataToUpdate['photoURL'] = currentUser!.photoURL;
      }
      
      // CHECK 2: Does firstName/lastName exist? If not, initialize.
      // This handles old accounts created before the fields were added.
      if (userData['firstName'] == null) {
        dataToUpdate['firstName'] = '';
      }
      if (userData['lastName'] == null) {
        dataToUpdate['lastName'] = '';
      }

      // If we found any missing data, update the document
      if (dataToUpdate.isNotEmpty) {
        await userRef.update(dataToUpdate);
        // Re-fetch the document to get the newly merged data
        return await userRef.get();
      }

      // No updates were needed, just return the document as-is
      return doc;
    }
  }

@override
  Widget build(BuildContext context) {
    // Set status bar icons to light (white) for the dark header
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error loading profile.'));
          }
          
          // Data is guaranteed to exist here
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          // Use ?? '' for robust null handling, although the future should ensure this.
          final String firstName = userData['firstName'] ?? '';
          final String lastName = userData['lastName'] ?? '';

          // Combine them for display, with a fallback
          final String displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
              ? '$firstName $lastName'.trim()
              : 'Student Name';
          final email = userData['email'] ?? 'student.email@example.com';
          final photoURL = userData['photoURL'];

          // The main widget is a Stack to layer all elements
          return Stack(
            children: [
              // --- START OF NEW LAYOUT ---
              Column(
                children: [
                  // 1. STATIC (NON-SCROLLING) PART
                  Padding(
                    padding: const EdgeInsets.only(top: 290),
                    child: Column(
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24), // Space before scrollable list
                      ],
                    ),
                  ),

                  // 2. SCROLLABLE (DYNAMIC) PART
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionHeader('Badges'),
                            _buildPlaceholderBox(height: 120),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Achievements'),
                            _buildPlaceholderBox(height: 180),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // --- END OF NEW LAYOUT ---

              // 3. The header background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/icons/rectangle.png', 
                  height: 265, 
                  fit: BoxFit.cover,
                ),
              ),

              // 4. The BeeHive logo and text
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
                          height: 28, 
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/icons/BeeHive.png',
                          height: 15, 
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. The Profile Picture
              Positioned(
                top: 150, 
                left: MediaQuery.of(context).size.width / 2 - 65,
                child: ClipPath(
                  clipper: HexClipper(),
                  child: Container(
                    width: 140,
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
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'S', // Default if no name is set
                              style: const TextStyle(
                                  fontSize: 60, color: Colors.black54),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              // 6. The Back and Edit buttons
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: widget.onGoToHome,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: IconButton(
                    icon:
                        const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () async {
                      // Pass the current Firestore data to the edit page
                      final bool? profileWasUpdated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            userData: userData, // Pass the entire map
                          ),
                        ),
                      );

                      // REFRESH FIX: If the profile was updated, reload the data.
                      if (profileWasUpdated == true && mounted) {
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
          fontSize: 12,
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
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ),
    );
  }
}