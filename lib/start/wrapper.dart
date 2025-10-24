import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/start/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loader.dart';
import 'email_verification.dart';

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
          // 🔄 While waiting for Firebase to check authentication
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader(); // ✅ Show your animated loader
          }

          // ✅ User logged in
          else if (snapshot.hasData) {
            User user = snapshot.data!;
            
            // Check if email is verified
            if (user.emailVerified) {
              // Check user role and navigate to appropriate homepage
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const CustomLoader();
                  }
                  
                  if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                    final role = roleSnapshot.data!.data() as Map<String, dynamic>?;
                    final userRole = role?['role'];
                    
                    if (userRole == 'teacher') {
                      return const TeacherHomePage();
                    } else if (userRole == 'student') {
                      return const StudentHomePage();
                    } else {
                      // Role not found or invalid, show error message
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(
                                'Role not found. Please contact admin.',
                                style: TextStyle(fontSize: 18),
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
                  } else {
                    // User document not found
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'User record not found.',
                              style: TextStyle(fontSize: 18),
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
                },
              );
            } else {
              // Redirect to email verification page for unverified users
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
}

