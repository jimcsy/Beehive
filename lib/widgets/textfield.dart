import 'package:flutter/material.dart';

// We name the class clearly. 'GlobalTextField' or 'CustomTextField' is perfect.
class CustomTextField extends StatelessWidget {
  
  // 1. Define final variables for all the inputs your function needed.
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final Widget? suffixIcon; // Added suffixIcon as an option

  // 2. Create a constructor to receive those values.
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.obscure = false, // Default to false, just like your function
    this.suffixIcon,
  }) : super(key: key);

  // 3. Your function's body becomes the 'build' method.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 12),
        cursorColor: const Color(0xFF443C36),
        // We call your input decoration logic directly
        decoration: _buildInputDecoration(label, suffixIcon: suffixIcon),
      ),
    );
  }

  // 4. Your helper function can live here, private to this widget.
  InputDecoration _buildInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: const Color(0xFF443C36).withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
      suffixIcon: suffixIcon,
    );
  }
}