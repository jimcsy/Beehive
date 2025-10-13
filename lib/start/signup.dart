import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/start/loader.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'email_verification.dart';
import 'google_sign_in.dart';

class SignupPage extends StatefulWidget {
  final String selectedRole;

  const SignupPage({super.key, required this.selectedRole});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Pick birthday (using date picker)
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _birthdayController.text =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    }
  }

  // 🟢 Email & Password Signup
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    // Simple validation
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // Store user data in Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'email': user.email,
        'role': widget.selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await user.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(user: user),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Please try logging in.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = e.message ?? 'Signup failed';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🟢 Google Signup
  Future<void> _signUpWithGoogle() async {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    try {
      await provider.googleLogin(context, widget.selectedRole);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed')),
      );
    }
  }

  // 🟢 Redirect User Based on Role
  void _redirectUser(String role) {
    Widget nextPage;
    switch (role.toLowerCase()) {
      case 'student':
        nextPage = const StudentHomePage(); // Replace with StudentHome()
        break;
      case 'teacher':
        nextPage = const TeacherHomePage(); // Replace with TeacherHome()
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Role not recognized. Please contact admin.")),
        );
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar:
            AppBar(title: Text('Sign Up as ${widget.selectedRole.capitalize()}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🟢 First Name
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),

              // 🟢 Last Name
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 15),

              // 🟢 Birthday (Date Picker)
              TextField(
                controller: _birthdayController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Birthday',
                  prefixIcon: const Icon(Icons.cake),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectBirthday(context),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),

              // Sign Up Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Sign Up'),
                    ),
              const SizedBox(height: 15),

              // Google Sign Up Button
              ElevatedButton.icon(
                icon: const Icon(Icons.account_circle),
                label: const Text('Sign Up with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: _signUpWithGoogle,
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: const Text(
                  "Already registered? Log in.",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔠 Helper
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
