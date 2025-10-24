import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'signup.dart';
import 'login.dart';

class ChooseRolePage extends StatefulWidget {
  const ChooseRolePage({super.key});

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  String? selectedRole;

  void navigateToSignup() {
    if (selectedRole != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupPage(selectedRole: selectedRole!), //Pass role based on selection
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_logo.png',
                height: 100,
              ),
              const SizedBox(height: 16),

              const Text(
                'CHOOSE ROLE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Welcome! Are you a student or a teacher?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // Student Button
              ElevatedButton(
                onPressed: () {
                  setState(() => selectedRole = 'student');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2CD),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 90),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selectedRole == 'student'
                          ? const Color(0xFFB47B24)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.school, size: 36), //change to match figma design
                    SizedBox(height: 8),
                    Text(
                      'I am a student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Learn, practice, and track progress.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              //Teacher Button
              ElevatedButton(
                onPressed: () {
                  setState(() => selectedRole = 'teacher');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2CD),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 90),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selectedRole == 'teacher'
                          ? const Color(0xFFB47B24)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person, size: 36), //change to match figma design
                    Text(
                      'I am a teacher',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create lessons and guide learners.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: navigateToSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB47B24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: const TextStyle(
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
