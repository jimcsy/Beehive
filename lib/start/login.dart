import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'homepage.dart';
import 'choose_role.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;

  // Email & password login
  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill in both email and password fields."),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No account found. Redirecting to Sign Up...")),
        );

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChooseRolePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
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

      if (isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New Google user. Redirecting to Sign Up...")),
        );

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChooseRolePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
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
    return Scaffold(
      // 🚫 No back button here
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signIn,
                  child: const Text("Login"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Sign in with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ChooseRolePage()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up here",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loader overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
