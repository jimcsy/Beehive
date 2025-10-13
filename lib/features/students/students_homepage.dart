import 'package:beehive/features/students/student_drawer.dart';
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
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    try {
      // 🔹 Try fetching the user document by UID
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
        // 🔹 If UID doc doesn’t exist, try fetching by email (for Google users)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const StudentDrawer(), // ✅ connects the drawer here

      appBar: AppBar(
        title: const Text("Student Homepage"),
        // ✅ Builder ensures correct context
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // ✅ works properly
              },
              tooltip: 'Open Menu',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: signout,
            tooltip: 'Logout',
          ),
        ],
      ),

      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, ${user?.email ?? "No user"}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '🎓 Role: ${role ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
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
