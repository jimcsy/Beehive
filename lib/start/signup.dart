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
  bool _stepOneCompleted = false; // <- tracks which step user is on

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

  void _goToStepTwo() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() {
      _stepOneCompleted = true;
    });
  }

  // 🟢 Email & Password Signup
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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

      await _firestore.collection('users').doc(user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'email': user.email,
        'role': widget.selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
      String message = e.message ?? 'Signup failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
  final provider = Provider.of<GoogleSignInProvider>(context, listen: false);

  // Check Step 1 fields first
  if (_firstNameController.text.isEmpty ||
      _lastNameController.text.isEmpty ||
      _birthdayController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in First Name, Last Name, and Birthday')),
    );
    return;
  }

  try {
    User? user = await provider.googleLogin(context, widget.selectedRole);

    if (user != null) {
      // Store additional data from Step 1
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'email': user.email,
        'role': widget.selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true ensures we don't overwrite Google fields
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In failed')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sign Up as ${widget.selectedRole.capitalize()}'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _stepOneCompleted ? _buildStepTwo() : _buildStepOne(),
        ),
      ),
    );
  }

  // Step 1: Name + Birthday
  Widget _buildStepOne() {
    return Column(
      children: [
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 15),
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
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _goToStepTwo,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }

  // Step 2: Email + Password or Google
  Widget _buildStepTwo() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 25),
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
    );
  }
}

// 🔠 Helper
extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
