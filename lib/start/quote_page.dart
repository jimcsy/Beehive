import 'package:beehive/start/choose_role.dart';
import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';

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
                  Text(
                    "Interactive problem-solving that’s effective, fun, and accessible for everyone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 95, 95, 95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 50,)
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
                  SizedBox(
                    width: 320,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseRolePage(),
                          ),
                        );
                      },
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
                      child: const Text("Continue"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Login(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
