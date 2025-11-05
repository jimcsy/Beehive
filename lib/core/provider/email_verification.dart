import 'package:beehive/core/services/firestore_services.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../features/teachers/teachers_homepage.dart';
import '../../features/students/students_homepage.dart';
import 'login.dart';

// --- 2. ADD THESE IMPORTS ---
import 'package:provider/provider.dart';



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

        // --- 3. CALL THE REFACTORED FUNCTION ---
        _navigateBasedOnRole(current.uid);
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    }
  }

  // --- 
  // --- 4. THIS ENTIRE FUNCTION IS REFACTORED ---
  // --- 
  Future<void> _navigateBasedOnRole(String uid) async {
    try {
      // Get the service from Provider
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      // Get the clean user model
      final userModel = await firestoreService.users.getUser(uid);

      if (userModel == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User record not found.'), backgroundColor: Colors.red),
        );
        return;
      }

      // Use the clean model to check the role and navigate
      if (userModel.role == 'teacher') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherHomePage(userModel: userModel), // <-- PASS MODEL
          ),
        );
      } else if (userModel.role == 'student') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentHomePage(userModel: userModel), // <-- PASS MODEL
          ),
        );
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
          SnackBar(
              content: Text('Error sending verification: $e'),
              backgroundColor: Colors.red),
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
    // ... (Your build method is unchanged as it's all UI) ...
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            _timer?.cancel();
            _cooldownTimer?.cancel();
            await _signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Login()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // top content
                        Center(
                          child: Container(
                            width: 300,
                            height: 300,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/icons/images/email.png',
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const Text(
                          'We have sent you an email',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            strutStyle: StrutStyle(
                              height: 1.8, 
                              forceStrutHeight: true,
                            ),
                            text: TextSpan(
                              style: const TextStyle(fontSize: 18, color: Colors.black),
                              children: [
                                const TextSpan(
                                  text: "We’ve sent a link to ",
                                ),
                                TextSpan(
                                  text: widget.user.email ?? 'your email',
                                  style: const TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w600, 
                                    color: Colors.black87,
                                  ),
                                ),
                                const TextSpan(
                                  text: " — just click it to verify your account!",
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Spacer(),
                        if (!isEmailVerified) const DotLoadingAnimation(),
                        const SizedBox(height: 22),

                        // bottom controls
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    canResendEmail ? resendVerificationEmail : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFA27221),
                                  foregroundColor: Colors.white,  
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50), 
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: Text(
                                  canResendEmail
                                      ? 'Resend Verification'
                                      : 'Resend in ${resendCooldown}s',
                                  style: const TextStyle(
                                      color: Colors.white,),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Didn't receive the email? Check your spam folder or try resending.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
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

// ... (DotLoadingAnimation class is unchanged) ...
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
                child: CircleAvatar(radius: 5, backgroundColor: Colors.amber),
              ),
            );
          }),
        );
      },
    );
  }
}