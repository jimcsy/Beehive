import 'package:beehive/start/login.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/app_logo.png',
              width: 175,
              height: 175,
            ),
            const SizedBox(
              height: 30,
            ),
            
            SizedBox(
            width: 200, // Full width like TextField
            height: 49, 
              child: ElevatedButton(
                onPressed: (){
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA27221), // Match TextField border or accent
                  foregroundColor: Colors.white,  // Text color
                  //padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  //elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Match TextField radius
                  ),
                  textStyle: TextStyle(
                    fontSize: 12, // Match TextField font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text("Start my Journey!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
