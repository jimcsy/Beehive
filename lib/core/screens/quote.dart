import 'package:beehive/core/provider/choose_role.dart';
import 'package:beehive/core/provider/login.dart';
import 'package:beehive/widgets/button.dart';
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: CustomPrimaryButton(
                      text: "Continue", 
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseRolePage(),
                          ),
                        );
                      },
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
