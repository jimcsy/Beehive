import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'homepage.dart';
import 'login.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn(
    serverClientId: '218809920637-3fm1tqd6gpmdn9tifnq22vdt5f33de54.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  Future<void> googleLogin(BuildContext context, String selectedRole) async {
    try {
      // 🌀 Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 🚪 Force logout before sign-in to show the account chooser
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // 🔑 Let user pick an account
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        Navigator.pop(context); // close loader
        return;
      }

      _user = googleUser;
      final googleAuth = await googleUser.authentication;

      // 🪪 Get Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // 🗄️ Check if user already exists in Firestore
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final docSnapshot = await userDoc.get();

      Navigator.pop(context); // close loader

      if (docSnapshot.exists) {
        // 🔁 If already exists, go to Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists, please log in.')),
        );

        // ⚡ Ensure sign-out so user can re-select accounts later
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      } else {
        // 🆕 Save user to Firestore
        await userDoc.set({
          'email': user.email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      }

      notifyListeners();
    } catch (e) {
      Navigator.pop(context); // close loader if error occurs
      debugPrint('⚠️ Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed, please try again.')),
      );
    }
  }

  // 🚪 Proper logout method
  Future<void> logout() async {
    try {
      await googleSignIn.disconnect(); // ensures Google account is fully cleared
    } catch (_) {
      // fallback if disconnect fails
      await googleSignIn.signOut();
    }
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }
}
