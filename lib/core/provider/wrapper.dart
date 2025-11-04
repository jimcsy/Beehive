// lib/core/screens/wrapper.dart

import 'package:beehive/core/provider/email_verification.dart';
import 'package:beehive/core/provider/loader.dart';
import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/core/screens/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// --- 1. IMPORT YOUR SERVICES AND MODELS ---
import 'package:beehive/core/models/user_model.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 🔄 While waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader();
          }

          // ✅ User logged in
          else if (snapshot.hasData) {
            User user = snapshot.data!;

            // Check if email is verified
            if (user.emailVerified) {
              // --- 2. THIS IS THE REFACTORED PART ---
              // Instead of a FutureBuilder for Firestore, we use one for our service
              return FutureBuilder<UserModel?>(
                // Get the FirestoreService from Provider and call getUser
                future: Provider.of<FirestoreService>(context, listen: false)
                    .getUser(user.uid),

                builder: (context, userModelSnapshot) {
                  if (userModelSnapshot.connectionState == ConnectionState.waiting) {
                    return const CustomLoader();
                  }

                  // Get the clean userModel object from the snapshot
                  final userModel = userModelSnapshot.data;

                  if (userModel != null) {
                    // --- 3. USE THE CLEAN MODEL ---
                    if (userModel.role == 'teacher') {
                      return TeacherHomePage(userModel: userModel);
                    } else if (userModel.role == 'student') {
                      return StudentHomePage(userModel: userModel);
                    } else {
                      // Role not found or invalid
                      return _buildErrorScreen(
                        'Role not found. Please contact admin.',
                      );
                    }
                  } else {
                    // User document not found in Firestore
                    return _buildErrorScreen(
                      'User record not found.',
                    );
                  }
                },
              );
              // --- END OF REFACTORED PART ---

            } else {
              // Redirect to email verification page
              return EmailVerificationPage(user: user);
            }
          }

          // 🚪 No user logged in
          else {
            return const LandingPage();
          }
        },
      ),
    );
  }

  // Helper widget to keep the build method clean
  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}