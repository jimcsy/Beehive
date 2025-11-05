import 'package:beehive/core/services/firestore_services.dart';
import 'package:beehive/features/students/students_homepage.dart';
import 'package:beehive/core/provider/loader.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <-- NO LONGER NEEDED
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/teachers/teachers_homepage.dart';
import '../provider/login.dart';

// --- 1. ADD IMPORTS FOR PROVIDER, SERVICE, AND MODEL ---
import 'package:provider/provider.dart';
import 'package:beehive/core/models/user_model.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn(
    serverClientId: '218809920637-3fm1tqd6gpmdn9tifnq22vdt5f33de54.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  Future<User?> googleLogin(
    BuildContext context,
    String selectedRole, {
    String? firstName,
    String? lastName,
    String? birthday,
  }) async {
    // --- 2. GET SERVICE FROM PROVIDER (before any 'await') ---
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

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

      // --- 3. REFACTORED: CHECK IF USER EXISTS VIA SERVICE ---
      final existingUser = await firestoreService.users.getUser(user!.uid);
      
      Navigator.pop(context); // close loader

      if (existingUser != null) {
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
        // --- 4. REFACTORED: CREATE USER VIA MODEL & SERVICE ---
        
        // Create the new UserModel object
        final newUserModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          role: selectedRole,
          firstName: firstName ?? '',
          lastName: lastName ?? '',
          birthday: birthday ?? '',
          // createdAt is handled by the service
        );
        
        // Save user to Firestore using the service
        await firestoreService.users.createUser(newUserModel);

        // --- 5. REFACTORED: NAVIGATE AND PASS THE MODEL ---
        if (selectedRole == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentHomePage(userModel: newUserModel), // <-- PASS MODEL
            ),
          );
        } else if (selectedRole == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherHomePage(userModel: newUserModel), // <-- PASS MODEL
            ),
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
      if (context.mounted) Navigator.pop(context);
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