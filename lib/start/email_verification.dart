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

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with WidgetsBindingObserver {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  int resendCooldown = 0;
  Timer? _timer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    isEmailVerified = widget.user.emailVerified;
    if (!isEmailVerified) _startPeriodicCheck();
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
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!isEmailVerified) checkEmailVerified();
    });
  }

  Future<void> checkEmailVerified() async {
    try {
      // reload the passed-in user then read the current user from FirebaseAuth
      await widget.user.reload();
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.emailVerified) {
        if (!mounted) return;
        setState(() => isEmailVerified = true);
        _timer?.cancel();
        _cooldownTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        _navigateBasedOnRole(current.uid);
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User record not found.'), backgroundColor: Colors.red),
        );
        return;
      }

      final role = doc.data()?['role'];
      if (role == 'teacher') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const TeacherHomePage()));
      } else if (role == 'student') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const StudentHomePage()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role not found. Please contact admin.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user role: $e')),
        );
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    if (!canResendEmail) return;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No signed-in user. Please sign in again.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      await currentUser.sendEmailVerification();

      if (!mounted) return;
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

      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => resendCooldown--);
        if (resendCooldown <= 0) {
          setState(() => canResendEmail = true);
          timer.cancel();
        }
      });
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error signing out')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD09A10);
    const Color goldDark = Color(0xFFB57A00);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // ensure column fills viewport so Spacer() works
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // top content
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 300,
                            height: 300,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/icons/images/email.png',
                              width: 300,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'We have sent you an email',
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.email ?? 'your email',
                          style:
                              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "We've sent an email verification on your email address. Click the link to verify your account.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (!isEmailVerified) const DotLoadingAnimation(),
                        const SizedBox(height: 22),

                        // fills remaining space and pushes the following buttons to bottom
                        const Spacer(),

                        // bottom controls (kept full width)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    canResendEmail ? resendVerificationEmail : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  disabledBackgroundColor: gold.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  shadowColor: goldDark,
                                ),
                                child: Text(
                                  canResendEmail
                                      ? 'Resend Verification'
                                      : 'Resend in ${resendCooldown}s',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Didn't receive the email? Check your spam folder or try resending.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🌙 Subtle 3-dot loading animation (non-distracting)
class DotLoadingAnimation extends StatefulWidget {
  const DotLoadingAnimation({super.key});

  @override
  State<DotLoadingAnimation> createState() => _DotLoadingAnimationState();
}

class _DotLoadingAnimationState extends State<DotLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        int activeDot = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedOpacity(
              opacity: index == activeDot ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: CircleAvatar(radius: 5, backgroundColor: Colors.blue),
              ),
            );
          }),
        );
      },
    );
  }
}