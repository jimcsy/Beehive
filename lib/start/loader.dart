import 'package:flutter/material.dart';

/// Custom Loader Widget
class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber, // or your app theme color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/gifs/loader.gif',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading, please wait...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
