import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/core/provider/loader.dart';
import 'package:beehive/core/provider/login.dart';
import 'package:beehive/widgets/button.dart';
import 'package:beehive/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NO LONGER NEEDED!
import 'package:provider/provider.dart';
import 'email_verification.dart';
import '../services/google_auth_services.dart';

// --- 2. ADD IMPORTS FOR SERVICE AND MODEL ---
import 'package:beehive/core/models/user_model.dart';

class SignupPage extends StatefulWidget {
  final String selectedRole;

  const SignupPage({super.key, required this.selectedRole});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // <-- 3. DELETE THIS

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _stepOneCompleted = false;
  bool _obscureText = true;

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

  // --- 
  // --- 4. REFACTORED _signUp ---
  // --- 
  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Get the service from Provider *before* the async gap
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      // Create auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // --- REPLACED RAW FIRESTORE CALL ---
      
      // 1. Create the new UserModel object
      final newUserModel = UserModel(
        uid: user!.uid,
        email: user.email!,
        role: widget.selectedRole,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthday: _birthdayController.text.trim(),
        // createdAt will be handled by the service
      );

      // 2. Call the service to create the user
      await firestoreService.users.createUser(newUserModel);
      
      // --- END OF REPLACEMENT ---

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 
  // --- 5. REFACTORED _signUpWithGoogle ---
  // --- 
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

    // Your GoogleSignInProvider already creates the user AND navigates.
    // All we have to do is call it and pass in the details.
    try {
      await provider.googleLogin(
        context,
        widget.selectedRole,
        // Pass the details from the controllers
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthday: _birthdayController.text.trim(),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed')),
        );
      }
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
            padding: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
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
        CustomTextField(controller: _firstNameController, label: 'First Name'),
        const SizedBox(height: 20),
        CustomTextField(controller: _lastNameController, label: 'Last Name'),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: CustomTextField(
            controller: _birthdayController, 
            label: 'Birthday', 
            suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.grey),
                onPressed: () => _selectBirthday(context),
              ),
            ),
          ),
        const SizedBox(height: 30),
        SizedBox(
          height: 50,
          child: CustomPrimaryButton(text: 'Next', onPressed: _goToStepTwo),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(controller: _emailController, label: 'Email Address'),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: CustomTextField(
            controller: _passwordController, 
            label: "Password",
            obscure: _obscureText,
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

        const SizedBox(height: 190),
        SizedBox(
          height: 50,
          child: CustomPrimaryButton(text: 'Sign up', onPressed: _signUp),
        ),
        
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(child: Divider(thickness: 1, color: Colors.grey)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Sign up with",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(thickness: 1, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
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
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}