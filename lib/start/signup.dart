import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/start/loader.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _stepOneCompleted = false;

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _birthdayController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill in First Name, Last Name, and Birthday')),
      );
      return;
    }

    try {
      User? user = await provider.googleLogin(context, widget.selectedRole);

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'birthday': _birthdayController.text.trim(),
          'email': user.email,
          'role': widget.selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                Image.asset(
                  './assets/icons/app_logo.png',
                  height: 80,
                ),
                const SizedBox(height: 10),

                const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                // Step Forms
                _stepOneCompleted ? _buildStepTwo() : _buildStepOne(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(_firstNameController, 'First Name'),
        const SizedBox(height: 16),
        _buildTextField(_lastNameController, 'Last Name'),
        const SizedBox(height: 16),
        TextField(
          controller: _birthdayController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Birthday',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFB47B24),
                width: 1.4
              ),
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFFB47B24),
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectBirthday(context),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _goToStepTwo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB47B24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Next',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(_emailController, 'Email Address'),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, 'Password', obscure: true),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB47B24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Sign up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 25),

        // Divider
        Row(
          children: const [
            Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Sign in with'),
            ),
            Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 15),

        GestureDetector(
          onTap: _signUpWithGoogle,
          child: Image.asset(
            './assets/icons/google_logo.png',
            height: 40,
          ),
        ),
        const SizedBox(height: 25),

        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      cursorColor: Color(0xFFB47B24),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFB47B24),
            width: 2.0,
          ),
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFFB47B24),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
