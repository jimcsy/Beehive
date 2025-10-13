import 'package:beehive/start/loader.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../features/teachers/teachers_homepage.dart';
import '../features/students/students_homepage.dart';

class EmailVerificationPage extends StatefulWidget {
  final User user;

  const EmailVerificationPage({super.key, required this.user});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> with WidgetsBindingObserver {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  bool isCheckingVerification = false;
  int resendCooldown = 0;
  Timer? _timer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    isEmailVerified = widget.user.emailVerified;

    if (!isEmailVerified) {
      _startPeriodicCheck();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isEmailVerified) {
      checkEmailVerified();
    }
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isEmailVerified) {
        checkEmailVerified();
      }
    });
  }

  Future<void> checkEmailVerified() async {
    if (isCheckingVerification) return;

    setState(() => isCheckingVerification = true);

    try {
      await widget.user.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        setState(() => isEmailVerified = true);
        _timer?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Wait a bit before redirect
          await Future.delayed(const Duration(milliseconds: 1200));

          if (mounted) {
            _navigateBasedOnRole(user.uid);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    } finally {
      if (mounted) setState(() => isCheckingVerification = false);
    }
  }

  /// 🔹 This checks the user's role in Firestore and navigates accordingly
  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final role = doc.data()?['role'];

        if (role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherHomePage()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role not found. Please contact admin.'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record not found.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user role: $e')),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    if (!canResendEmail) return;

    try {
      await widget.user.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.blue,
          ),
        );

        setState(() {
          canResendEmail = false;
          resendCooldown = 60;
        });

        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => resendCooldown--);
          if (resendCooldown <= 0) {
            setState(() => canResendEmail = true);
            timer.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending verification: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing out')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      isLoading: isCheckingVerification,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Verify Your Email'),
          actions: [
            TextButton(
              onPressed: _signOut,
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, size: 100, color: Colors.blue),
                const SizedBox(height: 30),
                const Text('Check Your Email',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.user.email ?? 'your email',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "We've sent a verification link to your email address. Please click the link to verify your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                if (isCheckingVerification)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Checking verification status...'),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCheckingVerification ? null : checkEmailVerified,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Check Verification Status'),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canResendEmail ? resendVerificationEmail : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(canResendEmail
                        ? 'Resend Verification Email'
                        : 'Resend in ${resendCooldown}s'),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Didn't receive the email? Check your spam folder or try resending.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
