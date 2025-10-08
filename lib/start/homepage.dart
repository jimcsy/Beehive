import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'google_sign_in.dart'; // ✅ import your GoogleSignInProvider

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> signout() async {
    try {
      // 🌀 Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final googleProvider = Provider.of<GoogleSignInProvider>(context, listen: false);

      // 🚪 Logout from both Google & Firebase
      await googleProvider.logout();

      // ✅ Dismiss loader
      Navigator.pop(context);

      // ✅ Navigate back to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } catch (e) {
      Navigator.pop(context); // close loader if error
      debugPrint('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Homepage"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: signout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user?.email ?? "No user"}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: signout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text("Logout"),
      ),
    );
  }
}
