import 'package:flutter/material.dart';

class TAboutPage extends StatelessWidget {
  const TAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: const Center(
        child: Text('About Page Content'),
      ),
    );
  }
}