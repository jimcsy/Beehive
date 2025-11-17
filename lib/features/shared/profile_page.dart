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
      // 1. NEW USER:
      // Document doesn't exist, create it.
      // We'll save the Gmail PFP (currentUser!.photoURL) right away.
      try {
        await userRef.set({
          'displayName': currentUser!.displayName,
          'email': currentUser!.email,
          'photoURL': currentUser!.photoURL, // <-- Saves the Gmail PFP
          'role': 'student', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          //'firstName': '', // You can pre-fill these if you want
          //'lastName': '',
        });
        // Return the new document we just created
        return await userRef.get();
      } catch (e) {
        throw Exception('Failed to create user profile: $e');
      }
    } else {
      // 2. EXISTING USER:
      // Document EXISTS. We need to check if it's missing data.
      final userData = doc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> dataToUpdate = {};

      // CHECK: Is the photoURL null in our database?
      if (userData['photoURL'] == null && currentUser!.photoURL != null) {
        // YES. The user has a Gmail PFP, but it's not in our database.
        // Let's update it.
        dataToUpdate['photoURL'] = currentUser!.photoURL;
      }

      // You can add more checks here if you want
      // if (userData['displayName'] == null && currentUser!.displayName != null) {
      //   dataToUpdate['displayName'] = currentUser!.displayName;
      // }

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

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final String firstName = userData?['firstName'] ?? '';
          final String lastName = userData?['lastName'] ?? '';

          // Combine them for display, with a fallback
          final String displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
              ? '$firstName $lastName'.trim()
              : 'Student Name';
          final email = userData?['email'] ?? 'student.email@example.com';
          final photoURL = userData?['photoURL'];

          // The main widget is a Stack to layer all elements
          return Stack(
            children: [
              // --- START OF NEW LAYOUT ---
              // This Column now replaces the SingleChildScrollView
              // It holds BOTH the static info and the scrollable list
              Column(
                children: [
                  // 1. STATIC (NON-SCROLLING) PART
                  // We use Padding to push this content down below the PFP
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
                  // Expanded tells this section to take all *remaining* space
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          // This makes the section headers align left
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

              // 3. The header background (NO CHANGE)
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

              // 4. The BeeHive logo and text (NO CHANGE)
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

              // 5. The Profile Picture (NO CHANGE)
              Positioned(
                top: 150, // Position it to overlap the header and body
                // Center horizontally
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
                                  : 'S',
                              style: const TextStyle(
                                  fontSize: 60, color: Colors.black54),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              // 6. The Back and Edit buttons (NO CHANGE)
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
                      final bool? profileWasUpdated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            userData: userData ?? {},
                          ),
                        ),
                      );

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

// --- Clipper Class (Only the Hexagonal one is needed now) --