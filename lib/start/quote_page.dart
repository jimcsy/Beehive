import 'package:beehive/start/choose_role.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class BuzzIntoCoding extends StatefulWidget {
  const BuzzIntoCoding({super.key});

  @override
  State<BuzzIntoCoding> createState() => _BuzzIntoCodingState();
}

class _BuzzIntoCodingState extends State<BuzzIntoCoding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // --- Center GIF and Text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // centers content vertically
                  children: [
                    SizedBox(
                      height: 350,
                      child: Image.asset(
                        'assets/icons/gifs/buzzintocoding.gif',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Interactive problem-solving that’s effective, fun, and accessible for everyone.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 95, 95, 95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),

              // --- Bottom-aligned buttons
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ChooseRolePage()),
                          );
                        },
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

                    // "Already have an account? Sign in"
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
                                  MaterialPageRoute(
                                      builder: (_) => const Login()),
                                );
                              },
                          ),
                        ],
                      ),
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
