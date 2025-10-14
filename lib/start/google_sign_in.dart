import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/start/loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../features/teachers/teachers_homepage.dart';
import 'login.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn(
    serverClientId: '218809920637-3fm1tqd6gpmdn9tifnq22vdt5f33de54.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  // Updated: Added optional parameters for firstName, lastName, birthday
  Future<User?> googleLogin(
    BuildContext context,
    String selectedRole, {
    String? firstName,
    String? lastName,
    String? birthday,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CustomLoader(),
      );

      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        Navigator.pop(context);
        return null;
      }

      _user = googleUser;
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final docSnapshot = await userDoc.get();

      Navigator.pop(context); // close loader

      if (docSnapshot.exists) {
        // Account already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists, please log in.')),
        );
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      } else {
        // Save user to Firestore
        await userDoc.set({
          'email': user.email,
          'role': selectedRole,
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'birthday': birthday ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Redirect based on role
        if (selectedRole == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else if (selectedRole == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherHomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown role, please contact admin.')),
          );
        }
      }

      notifyListeners();
      return user;
    } catch (e) {
      Navigator.pop(context);
      debugPrint('⚠️ Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed, please try again.')),
      );
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await googleSignIn.disconnect();
    } catch (_) {
      await googleSignIn.signOut();
    }
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }
}
