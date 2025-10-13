import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/start/loader.dart';
import 'package:beehive/start/quote_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../features/teachers/teachers_homepage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true; // Add this in your State class
  
  Future<void> signIn() async {
  final String userEmail = email.text.trim();
  final String userPassword = password.text.trim();

  // Step 1: Validation
  if (userEmail.isEmpty || userPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Please fill in both email and password fields."),
      ),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    // Step 2: Firebase Sign-in
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: userEmail,
      password: userPassword,
    );

    // Step 3: Get UID and fetch Firestore data
    final String uid = userCredential.user!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final role = userDoc.data()?['role'] ?? '';

      // Step 4: Navigate based on user role
      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomePage()),
        );
      } else if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherHomePage()),
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
  } on FirebaseAuthException catch (e) {
    // Step 5: Handle specific Firebase errors
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
    // Step 6: Catch unexpected errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}


  // Google login
Future<void> signInWithGoogle() async {
  setState(() => isLoading = true);
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

    // Sign out first to allow choosing a different account
    await googleSignIn.signOut();

    final GoogleSignInAccount? gUser = await googleSignIn.signIn();
    if (gUser == null) {
      setState(() => isLoading = false);
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuzzIntoCoding()),
      );
    } else {
      // ✅ Fetch the user's role from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['role'] == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherHomePage()),
        );
      } else if (doc.exists && doc.data()?['role'] == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentHomePage()),
        );
      } else {
        // fallback if no role found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No role found for this account.")),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google sign-in failed: $e')),
    );
  } finally {
    setState(() => isLoading = false);
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
                      padding: EdgeInsets.zero, // no extra scroll padding
                      child: Padding(
                        // minimal padding only at sides & bottom
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "Sign In",
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
                              child: TextField(
                                controller: email,
                                style: const TextStyle(fontSize: 12),
                                cursorColor: Color(0xFF443C36),
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF443C36).withOpacity(0.3), width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            

                            // Password field
                            SizedBox(
                              height: 50,
                              child: TextField(
                                controller: password,
                                obscureText: _obscureText,
                                style: const TextStyle(fontSize: 12),
                                cursorColor: Color(0xFF443C36),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF443C36).withOpacity(0.3), width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
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
                            const SizedBox(height: 30),

                            // Buttons
                            SizedBox(
                              width: double.infinity, // Full width like TextField
                              height: 50, 
                              child: ElevatedButton(
                                onPressed: signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFA27221),
                                  foregroundColor: Colors.white,  // Text color
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  //elevation: 4, // Drop shadow
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50), // Match TextField radius
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 12, // Match TextField font size
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text("Sign in"),
                              ),
                            ),

                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BuzzIntoCoding(),
                                  ),
                                );
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
                                          "Sign in with",
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

                            /*ElevatedButton.icon(
                              onPressed: signInWithGoogle,
                              icon: const Icon(Icons.login),
                              label: const Text("Sign in with Google"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),*/
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
                                  //elevation: 4,
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
                                      text: "Sign up here",
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