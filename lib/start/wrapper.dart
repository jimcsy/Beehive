import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'login.dart';
import 'loader.dart';

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
            return const Homepage();
          }

          // 🚪 No user logged in
          else {
            return const Login();
          }
        },
      ),
    );
  }
}

