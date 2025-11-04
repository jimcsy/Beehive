import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/core/provider/forgot_password.dart';
import 'package:beehive/core/provider/loader.dart';
import 'package:beehive/core/screens/quote.dart';
import 'package:beehive/widgets/button.dart';
import 'package:beehive/widgets/textfield.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- This is now REMOVED!
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/teachers/teachers_homepage.dart';

// --- 1. ADD THESE IMPORTS ---
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;

  Future<void> signIn() async {
    final String userEmail = email.text.trim();
    final String userPassword = password.text.trim();

    if (userEmail.isEmpty || userPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill in both email and password fields."),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // --- 2. GET SERVICE BEFORE THE 'AWAIT' ---
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      // Step 2: Firebase Sign-in
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      // --- 3. REFACTORED: USE SERVICE AND MODEL ---
      final String uid = userCredential.user!.uid;
      // Fetch the clean user model from our service
      final userModel = await firestoreService.getUser(uid);

      if (userModel != null) {
        // Check if the widget is still on-screen before navigating
        if (!mounted) return; 

        // Step 4: Navigate based on the clean model's role
        if (userModel.role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // Pass the model to the homepage
              builder: (context) => StudentHomePage(userModel: userModel),
            ),
          );
        } else if (userModel.role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // Pass the model to the homepage
              builder: (context) => TeacherHomePage(userModel: userModel),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ No role assigned to this account."),
            ),
          );
        }
      } else {
        // Handle missing user document
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Account exists but no user data found."),
          ),
        );
      }
      // --- END OF REFACTORED PART ---

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Try again later.';
          break;
        case 'invalid-credential':
          message =
              'Authentication failed. Please check your email and password.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Google login
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);

    // --- GET SERVICE BEFORE 'AWAIT' ---
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? gUser = await googleSignIn.signIn();
      
      if (gUser == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      final uid = userCredential.user?.uid;

      if (isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New Google user. Redirecting to Sign Up...")),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BuzzIntoCoding()),
        );
      } else {
        // --- 4. REFACTORED GOOGLE Log in ---
        
        // Fetch the user's model from our service
        final userModel = await firestoreService.getUser(uid!);

        if (!mounted) return;

        if (userModel != null) {
           if (userModel.role == 'teacher') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherHomePage(userModel: userModel),
              ),
            );
          } else if (userModel.role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHomePage(userModel: userModel),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ No role found for this account.")),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ User data not found.")),
          );
        }
        // --- END OF REFACTORED PART ---
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      isLoading: isLoading,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:[
                Color(0xFFA0701F),
                Color(0xFFE8A319),
                Color(0xFFF4E3C2),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                  child: Image.asset(
                    'assets/icons/app_logo_W.png',
                    width: 150,
                    height: 150,
                  ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero, 
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "Log in",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email field
                            SizedBox(
                              height: 50,
                              child: CustomTextField(
                                controller: email, 
                                label: "Email"),
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            SizedBox(
                              height: 50,
                              child: CustomTextField(
                                controller: password,
                                label: 'Password',
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
                            const SizedBox(height: 30),

                            CustomPrimaryButton(text: "Log in", onPressed: signIn),

                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                  showForgotPasswordModal(context);
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                ),
                            ),

                            const SizedBox(height: 30),

                            Column(
                              children: [
                                Container(
                                  child: Row(
                                    children: [
                                      Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          "Log in with",
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
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            SizedBox(
                              width: 48,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: signInWithGoogle,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Image.asset( 
                                  'assets/icons/google_logo.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            // Bottom text
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BuzzIntoCoding(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Color(0xFF443C36),
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: "Sign up",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
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