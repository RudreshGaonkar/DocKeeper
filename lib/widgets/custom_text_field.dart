import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller; // Controller for the text field
  final String labelText; // Label text for the field
  final IconData icon; // Icon to display in the field
  final bool obscureText; // Whether the text is hidden (for passwords)
  final Widget? suffixIcon; // Optional suffix icon

  CustomTextField({
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false, // Default: not obscured
    this.suffixIcon, 
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText, // Hide text if true
      decoration: InputDecoration(
        labelText: labelText, // Set label text
        prefixIcon: Icon(icon), // Set prefix icon
        suffixIcon: suffixIcon, // Optional suffix icon
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      ),
    );
  }
}
