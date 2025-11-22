import 'package:beehive/core/models/user_model.dart';
import 'package:beehive/core/provider/email_verification.dart';
import 'package:beehive/core/provider/loader.dart';
import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/core/screens/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

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
              return StreamBuilder<UserModel?>(
            // Get the FirestoreService and call the NEW stream function
            stream: Provider.of<FirestoreService>(context, listen: false)
                .users
                .getUserStream(user.uid),

            builder: (context, userModelSnapshot) {
              // 1. Still loading
              if (userModelSnapshot.connectionState == ConnectionState.waiting) {
                return const CustomLoader();
              }

              // 2. Handle any errors from the stream
              if (userModelSnapshot.hasError) {
                return _buildErrorScreen(
                  'Error loading user: ${userModelSnapshot.error}',
                );
              }

              // 3. Got data, but it's null (user doc not found)
              final userModel = userModelSnapshot.data;
              if (userModel == null) {
                return _buildErrorScreen(
                  'User record not found. Please contact admin.',
                );
              }

              // 4. Success! We have a user.
              if (userModel.role == 'teacher') {
                return TeacherHomePage(userModel: userModel);
              } else if (userModel.role == 'student') {
                return StudentHomePage(userModel: userModel);
              } else {
                return _buildErrorScreen(
                  'Role not found. Please contact admin.',
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
    // --- 3. THIS IS THE FIX: REMOVED THE SCAFFOLD ---
    return Center(
      // --- END OF FIX ---
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
    );
  }
}