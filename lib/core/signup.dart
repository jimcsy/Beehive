import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/features/teachers/teachers_homepage.dart';
import 'package:beehive/core/loader.dart';
import 'package:beehive/core/login.dart';
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
  bool _obscureText = true; // For password field

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

  // --- REUSABLE STYLE FUNCTION (Copied from Login) ---
  /// This function builds the InputDecoration shared by the text fields.
  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Color(0xFF443C36).withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
      suffixIcon: suffixIcon,
    );
  }
  // ---------------------------------------------------

  // --- REUSABLE BUTTON STYLE (Copied from Login) ---
  ButtonStyle _getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFA27221),
      foregroundColor: Colors.white, // Text color
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50), // Match login radius
      ),
      textStyle: TextStyle(
        fontSize: 12, // Match login font size
        fontWeight: FontWeight.w600,
      ),
    );
  }
  // ---------------------------------------------------

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
            padding: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24), // Added bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  './assets/icons/app_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 10),
                const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontSize: 16,
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
        const SizedBox(height: 20),
        _buildTextField(_lastNameController, 'Last Name'),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: TextField(
            controller: _birthdayController,
            readOnly: true,
            style: const TextStyle(fontSize: 12), // Match style
            cursorColor: Color(0xFF443C36), // Match style
            decoration: _buildInputDecoration(
              'Birthday',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.grey),
                onPressed: () => _selectBirthday(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox( // <-- Added SizedBox for height
          height: 50,
          child: ElevatedButton(
            onPressed: _goToStepTwo,
            style: _getPrimaryButtonStyle(), // <-- Applied style
            child: const Text(
              'Next',
              // Text style is now defined in _getPrimaryButtonStyle
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
        // Updated Password Field
        SizedBox(
          height: 50,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            style: const TextStyle(fontSize: 12),
            cursorColor: Color(0xFF443C36),
            decoration: _buildInputDecoration(
              "Password",
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 190),
        SizedBox( // <-- Added SizedBox for height
          height: 50,
          child: ElevatedButton(
            onPressed: _signUp,
            style: _getPrimaryButtonStyle(), // <-- Applied style
            child: const Text(
              'Sign up',
              // Text style is now defined in _getPrimaryButtonStyle
            ),
          ),
        ),
        const SizedBox(height: 25),

        // Divider
        Row(
          children: [ // <-- Removed const
            Expanded(child: Divider(thickness: 1, color: Colors.grey)), // <-- Matched login
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12), // <-- Matched login
              child: Text( // <-- Matched login
                "Sign up with",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(thickness: 1, color: Colors.grey)), // <-- Matched login
          ],
        ),
        const SizedBox(height: 20), // <-- Matched login

        Center( // <-- Added Center
          child: SizedBox( // <-- Added SizedBox
            width: 48,
            height: 48,
            child: ElevatedButton( // <-- Changed from GestureDetector
              onPressed: _signUpWithGoogle,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Image.asset(
                './assets/icons/google_logo.png',
                height: 24, 
                width: 24, 
              ),
            ),
          ),
        ),
        const SizedBox(height: 30), 

        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF443C36),
                fontSize: 16, 
              ),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in', 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
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

  // Updated _buildTextField to use the reusable decoration
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false}) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 12), // Added style
        cursorColor: Color(0xFF443C36),
        decoration: _buildInputDecoration(label), // --- STYLE APPLIED ---
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

