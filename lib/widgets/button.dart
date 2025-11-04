import 'package:flutter/material.dart';

class CustomPrimaryButton extends StatelessWidget {
  
  // 1. Define final variables for the parts that will change.
  final String text;
  final VoidCallback? onPressed;

  // 2. Create the constructor.
  const CustomPrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  // 3. Your code goes into the 'build' method.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // 4. Use your variables
        onPressed: onPressed,
        
        // 5. Keep your custom style right here
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA27221),
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 4. Use your variables
        child: Text(text), // Use the 'text' variable
      ),
    );
  }
}