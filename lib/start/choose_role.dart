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
          builder: (_) => SignupPage(selectedRole: selectedRole!), 
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
          padding: EdgeInsets.only(left: 24, right: 24, top: 56, bottom: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_logo.png',
                height: 100,
              ),
              const SizedBox(height: 10),

              const Text(
                'CHOOSE ROLE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 24),
                child: Column(
                  children: [
                    const Text(
                  'Welcome! Are you a student or a teacher?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Student Button
                SizedBox(
                  height: 170,
                  child: ElevatedButton(
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
                        Opacity(
                          opacity: 0.5,
                          child: Icon(Icons.person, size: 30)
                        ), //
                        SizedBox(height: 8),
                        Text(
                          'I am a student',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Learn, practice, and track progress.',
                          style: TextStyle(fontSize: 12, color: Color.fromARGB(123, 0, 0, 0)), textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                //Teacher Button
                SizedBox(
                  height: 170,
                  child: ElevatedButton(
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
                        Opacity(
                          opacity: 0.5,
                          child: Icon(Icons.menu_book, size: 30)
                        ), //change to match figma design
                        SizedBox(height: 8),
                        Text(
                          'I am a teacher',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create lessons and guide learners.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color.fromARGB(123, 0, 0, 0)), 
                        ),
                      ],
                    ),
                  ),
                ),
                  ],
                ),
              ),
              
            Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 320,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: navigateToSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA27221),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text("Next"),
                  ),
                ),
                const SizedBox(height: 10),
                // Bottom text
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Color(0xFF443C36),
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Log in",
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
            SizedBox(height: 30,)
            ],
          ),
        ),
      ),
    );
  }
}