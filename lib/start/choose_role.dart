import 'package:flutter/material.dart';
import 'signup.dart'; // make sure this path matches your structure

class ChooseRolePage extends StatelessWidget {
  const ChooseRolePage({super.key});

  void navigateToSignup(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPage(selectedRole: role), // pass the role
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select your role to continue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Student Button
              ElevatedButton.icon(
                icon: const Icon(Icons.school),
                label: const Text('I am a Student'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => navigateToSignup(context, 'student'),
              ),
              const SizedBox(height: 20),

              // Teacher Button
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('I am a Teacher'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => navigateToSignup(context, 'teacher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
