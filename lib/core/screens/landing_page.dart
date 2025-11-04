import 'package:beehive/core/provider/login.dart';
import 'package:beehive/widgets/button.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: CustomPrimaryButton( 
                text: "Start my Journey!", 
                onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
