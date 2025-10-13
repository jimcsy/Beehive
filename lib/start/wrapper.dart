import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/start/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/teachers/teachers_homepage.dart';
import 'login.dart';
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
              return const StudentHomePage();
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

