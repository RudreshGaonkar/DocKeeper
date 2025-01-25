// custom_button.dart
// A reusable custom button widget
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text; // The text displayed on the button
  final VoidCallback onPressed; // The function to execute on button press
  final Color color; // The button background color
  final Color textColor; // The text color

  CustomButton({
    required this.text,
    required this.onPressed,
    this.color = Colors.blue, // Default button color
    this.textColor = Colors.white, // Default text color
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Set the background color
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor, // Set the text color
          fontSize: 16, // Text size
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}